RSpec.describe API::Teachers::SchoolTransfers::Query do
  include SchoolTransferHelpers

  it_behaves_like "a query that avoids includes" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:params) { { lead_provider_id: lead_provider.id } }

    before { build_new_school_transfer(teacher:, lead_provider:) }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:ect_at_school_periods)).to be_loaded }
      it { expect(result.association(:mentor_at_school_periods)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.association(:earliest_training_period)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.earliest_training_period.association(:school_partnership)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.earliest_training_period.school_partnership.association(:school)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.earliest_training_period.association(:active_lead_provider)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.earliest_training_period.active_lead_provider.association(:lead_provider)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.association(:latest_training_period)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.latest_training_period.association(:school_partnership)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.latest_training_period.school_partnership.association(:school)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.latest_training_period.association(:active_lead_provider)).to be_loaded }
      it { expect(result.ect_at_school_periods.last.latest_training_period.active_lead_provider.association(:lead_provider)).to be_loaded }
    end

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:query) { described_class.new(lead_provider_id: lead_provider.id) }

    before { build_new_school_transfer(teacher:, lead_provider:) }

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
      school_period1 = create_school_period(teacher1, from: 2.years.ago, to: 1.year.ago)
      add_training_period(school_period1, from: 2.years.ago, to: 1.year.ago, programme_type: :school_led)
      school_period2 = create_school_period(teacher1, from: 1.year.ago)
      add_training_period(school_period2, from: 1.year.ago, programme_type: :provider_led, with: lead_provider)

      school_period3 = create_school_period(teacher2, from: 2.years.ago, to: 1.year.ago)
      add_training_period(school_period3, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: other_lead_provider)
      school_period4 = create_school_period(teacher2, from: 1.year.ago)
      add_training_period(school_period4, from: 1.year.ago, programme_type: :provider_led, with: lead_provider)

      school_period5 = create_school_period(teacher3, from: 2.years.ago, to: 1.year.ago)
      add_training_period(school_period5, from: 2.years.ago, to: 1.year.ago, programme_type: :school_led)
      school_period6 = create_school_period(teacher3, from: 1.year.ago, to: 1.week.ago)
      add_training_period(school_period6, from: 1.year.ago, to: 1.week.ago, programme_type: :provider_led, with: other_lead_provider)

      school_period7 = create_school_period(teacher4, from: 3.years.ago, to: 1.week.ago, type: :mentor)
      add_training_period(school_period7, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: lead_provider)
      add_training_period(school_period7, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: lead_provider)
      add_training_period(school_period7, from: 1.year.ago, to: 1.week.ago, programme_type: :provider_led, with: other_lead_provider)

      school_period8 = create_school_period(teacher5, from: 2.years.ago, to: 1.year.ago, type: :mentor)
      add_training_period(school_period8, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: other_lead_provider)
      school_period9 = create_school_period(teacher5, from: 1.year.ago, type: :mentor)
      add_training_period(school_period9, from: 1.year.ago, to: 1.week.ago, programme_type: :provider_led, with: lead_provider)
    end

    describe "filtering" do
      describe "by `lead_provider_id`" do
        let(:query) { described_class.new(lead_provider_id:) }

        context "when the lead provider has participants with transfers" do
          let(:lead_provider_id) { lead_provider.id }

          it { is_expected.to contain_exactly(teacher2, teacher5) }
        end

        context "when the other lead provider has participants with transfers" do
          let(:lead_provider_id) { other_lead_provider.id }

          it { is_expected.to contain_exactly(teacher3, teacher5) }
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

        before do
          freeze_time
          teacher1.touch(:api_updated_at, time: 10.days.ago)
          teacher2.touch(:api_updated_at, time: 7.days.ago)
          teacher5.touch(:api_updated_at, time: 4.days.ago)
        end

        context "when `updated_since` is provided" do
          let(:updated_since) { 7.days.ago }

          it { is_expected.to contain_exactly(teacher2, teacher5) }
        end

        context "when `updated_since` is blank" do
          let(:updated_since) { "" }

          it { is_expected.to contain_exactly(teacher1, teacher2, teacher5) }
        end

        context "when `updated_since` is nil" do
          let(:updated_since) { nil }

          it { is_expected.to contain_exactly(teacher1, teacher2, teacher5) }
        end
      end
    end

    describe "ordering" do
      let(:lead_provider_id) { lead_provider.id }

      before do
        teacher1.touch(:api_updated_at, time: 3.days.ago)
        teacher2.touch(:api_updated_at, time: 2.days.ago)
        teacher5.touch(:api_updated_at, time: 4.days.ago)
      end

      describe "default order" do
        let(:query) { described_class.new(lead_provider_id:) }

        it { is_expected.to eq([teacher1, teacher2, teacher5]) }
      end

      describe "order by created_at, in descending order" do
        let(:query) do
          described_class.new(lead_provider_id:, sort: { created_at: :desc })
        end

        it { is_expected.to eq([teacher5, teacher2, teacher1]) }
      end

      describe "order by updated_at, in descending order" do
        let(:query) do
          described_class.new(lead_provider_id:, sort: { updated_at: :desc })
        end

        it { is_expected.to eq([teacher2, teacher1, teacher5]) }
      end

      describe "order by updated_at, in ascending order" do
        let(:query) do
          described_class.new(lead_provider_id:, sort: { updated_at: :asc })
        end

        it { is_expected.to eq([teacher5, teacher1, teacher2]) }
      end
    end
  end
end
