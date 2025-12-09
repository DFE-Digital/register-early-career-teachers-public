RSpec.describe API::Teachers::SchoolTransfers::Query do
  include SchoolTransferHelpers

  it_behaves_like "a query that avoids includes" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:params) { { lead_provider_id: lead_provider.id } }

    before do
      build_new_school_transfer(teacher:, lead_provider:)
      Metadata::Handlers::Teacher.new(teacher).refresh_metadata!
    end
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:lead_provider_metadata)).to be_loaded }
      it { expect(result.association(:finished_induction_period)).to be_loaded }
      it { expect(result.association(:ect_at_school_periods)).to be_loaded }
      it { expect(result.association(:mentor_at_school_periods)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.association(:earliest_training_period)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.earliest_training_period.association(:lead_provider)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.association(:latest_training_period)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.latest_training_period.association(:lead_provider)).to be_loaded }
    end

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:query) { described_class.new(lead_provider_id: lead_provider.id) }

    before do
      build_new_school_transfer(teacher:, lead_provider:)
      Metadata::Handlers::Teacher.new(teacher).refresh_metadata!
    end

    describe "#school_transfers" do
      subject(:result) { query.school_transfers.first }

      include_context "preloaded associations"
    end
  end

  describe "#school_transfers" do
    subject(:school_transfers) { query.school_transfers }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

    let(:teacher1) { FactoryBot.create(:teacher) }
    let(:teacher2) { FactoryBot.create(:teacher) }
    let(:teacher3) { FactoryBot.create(:teacher) }
    let(:teacher4) { FactoryBot.create(:teacher) }
    let(:teacher5) { FactoryBot.create(:teacher) }

    before do
      build_new_school_transfer(teacher: teacher1, lead_provider:)
      build_ignored_transfer(teacher: teacher2, lead_provider:)
      build_new_provider_transfer(teacher: teacher3, leaving_lead_provider: lead_provider, joining_lead_provider: other_lead_provider, type: :mentor)
      build_unknown_transfer_for_finished_school_period(teacher: teacher4, lead_provider: other_lead_provider)
      build_new_school_transfer(teacher: teacher5, lead_provider:)

      [teacher1, teacher2, teacher3, teacher4, teacher5].each do
        Metadata::Handlers::Teacher.new(it).refresh_metadata!
      end
    end

    describe "filtering" do
      describe "by `lead_provider_id`" do
        let(:query) { described_class.new(lead_provider_id:) }

        context "when the lead provider has participants with transfers" do
          let(:lead_provider_id) { lead_provider.id }

          it { is_expected.to contain_exactly(teacher1, teacher3, teacher5) }
        end

        context "when the other lead provider has participants with transfers" do
          let(:lead_provider_id) { other_lead_provider.id }

          it { is_expected.to contain_exactly(teacher3, teacher4) }
        end

        context "when there are no participants with transfers" do
          let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

          it { is_expected.to be_empty }
        end

        context "when `lead_provider_id` is blank" do
          let(:lead_provider_id) { "" }

          it { is_expected.to be_empty }
        end

        context "when `lead_provider_id` is nil" do
          let(:lead_provider_id) { nil }

          it { is_expected.to be_empty }
        end
      end

      describe "by `updated_since`" do
        let(:query) { described_class.new(lead_provider_id:, updated_since:) }
        let(:lead_provider_id) { lead_provider.id }
        let(:transfer_dates) { {} }

        before do
          transfer_dates.each do |teacher, api_transfer_updated_at|
            teacher.ect_at_school_periods.each do |school_period|
              school_period.earliest_training_period&.update!(api_transfer_updated_at: api_transfer_updated_at[:joining])
              school_period.latest_training_period&.update!(api_transfer_updated_at: api_transfer_updated_at[:leaving])
            end

            teacher.mentor_at_school_periods.each do |school_period|
              school_period.earliest_training_period&.update!(api_transfer_updated_at: api_transfer_updated_at[:joining])
              school_period.latest_training_period&.update!(api_transfer_updated_at: api_transfer_updated_at[:leaving])
            end
          end
        end

        context "when filtering `updated_since` (joining ECT training period)" do
          let(:transfer_dates) do
            {
              teacher1 => { joining: 10.days.ago, leaving: 1.year.ago },
              teacher3 => { joining: 1.year.ago, leaving: 1.year.ago },
              teacher5 => { joining: 1.year.ago, leaving: 1.year.ago }
            }
          end
          let(:updated_since) { 11.days.ago }

          it { expect(subject).to contain_exactly(teacher1) }
        end

        context "when filtering `updated_since` (leaving ECT training period)" do
          let(:transfer_dates) do
            {
              teacher1 => { joining: 1.year.ago, leaving: 11.days.ago },
              teacher3 => { joining: 1.year.ago, leaving: 1.year.ago },
              teacher5 => { joining: 1.year.ago, leaving: 12.days.ago }
            }
          end
          let(:updated_since) { 13.days.ago }

          it { expect(subject).to contain_exactly(teacher1, teacher5) }
        end

        context "when filtering `updated_since` (joining mentor training period)" do
          let(:transfer_dates) do
            {
              teacher1 => { joining: 1.year.ago, leaving: 1.year.ago },
              teacher3 => { joining: 1.day.ago, leaving: 1.year.ago },
              teacher5 => { joining: 1.year.ago, leaving: 1.year.ago }
            }
          end
          let(:updated_since) { 2.days.ago }

          it { expect(subject).to be_empty } # teacher3 only has a leaving transfer for the LP
        end

        context "when filtering `updated_since` (leaving mentor training period)" do
          let(:transfer_dates) do
            {
              teacher1 => { joining: 1.year.ago, leaving: 1.year.ago },
              teacher3 => { joining: 1.year.ago, leaving: 21.days.ago },
              teacher5 => { joining: 1.year.ago, leaving: 1.year.ago }
            }
          end
          let(:updated_since) { 22.days.ago }

          it { expect(subject).to contain_exactly(teacher3) }
        end

        context "when `updated_since` is blank" do
          let(:updated_since) { "" }

          it { is_expected.to contain_exactly(teacher1, teacher3, teacher5) }
        end
      end
    end

    describe "ordering" do
      let(:lead_provider_id) { lead_provider.id }

      describe "default order" do
        let(:query) { described_class.new(lead_provider_id:) }

        it { is_expected.to eq([teacher1, teacher3, teacher5]) }
      end

      describe "order by created_at, in descending order" do
        let(:query) do
          described_class.new(lead_provider_id:, sort: { created_at: :desc })
        end

        it { is_expected.to eq([teacher5, teacher3, teacher1]) }
      end
    end
  end

  describe "#school_transfers_by_api_id" do
    subject(:school_transfers_by_api_id) do
      query.school_transfers_by_api_id(api_id)
    end

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:query) { described_class.new(lead_provider_id: lead_provider.id) }

    before do
      build_new_school_transfer(teacher:, lead_provider:)
      Metadata::Handlers::Teacher.new(teacher).refresh_metadata!
    end

    context "when the teacher is in the filtered query" do
      let(:api_id) { teacher.api_id }

      it { is_expected.to eq(teacher) }
    end

    context "when the teacher is not in the filtered query" do
      let(:api_id) { FactoryBot.create(:teacher).api_id }

      it "raises an error" do
        expect { school_transfers_by_api_id }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the teacher does not exist" do
      let(:api_id) { "NONEXISTENT" }

      it "raises an error" do
        expect { school_transfers_by_api_id }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when `api_id` is nil" do
      let(:api_id) { nil }

      it "raises an error" do
        expect { school_transfers_by_api_id }
          .to raise_error(ArgumentError, "api_id needed")
      end
    end
  end

  describe "#school_transfers_by_id" do
    subject(:school_transfers_by_id) do
      query.school_transfers_by_id(id)
    end

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:query) { described_class.new(lead_provider_id: lead_provider.id) }

    before do
      build_new_school_transfer(teacher:, lead_provider:)
      Metadata::Handlers::Teacher.new(teacher).refresh_metadata!
    end

    context "when the teacher is in the filtered query" do
      let(:id) { teacher.id }

      it { is_expected.to eq(teacher) }
    end

    context "when the teacher is not in the filtered query" do
      let(:id) { FactoryBot.create(:teacher).id }

      it "raises an error" do
        expect { school_transfers_by_id }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the teacher does not exist" do
      let(:id) { "NONEXISTENT" }

      it "raises an error" do
        expect { school_transfers_by_id }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when `id` is nil" do
      let(:id) { nil }

      it "raises an error" do
        expect { school_transfers_by_id }
          .to raise_error(ArgumentError, "id needed")
      end
    end
  end
end
