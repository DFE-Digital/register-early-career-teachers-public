RSpec.describe API::Teachers::UnfundedMentors::Query, :with_metadata do
  # Helper method to create a full ECT/Mentor setup
  def create_ect_and_unfunded_mentor_setup(lead_provider_id: nil)
    ect = FactoryBot.create(:teacher)
    school_partnership = if lead_provider_id.present?
                           SchoolPartnership.joins(lead_provider_delivery_partnership: :active_lead_provider).where(active_lead_provider: { lead_provider_id: }).first
                         else
                           FactoryBot.create(:school_partnership)
                         end
    ect_at_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, teacher: ect, started_on: 2.months.ago)
    ect_training_period = FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, school_partnership:, ect_at_school_period:)

    unfunded_mentor = FactoryBot.create(:teacher)
    unfunded_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: unfunded_mentor, started_on: 2.months.ago)

    latest_mentorship_period = FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: ect_at_school_period,
      mentor: unfunded_mentor_at_school_period,
      started_on: ect_training_period.started_on + 1.week
    )

    # Use the ECT's lead provider if not provided
    effective_lead_provider_id = lead_provider_id || ect.lead_provider_metadata.first.lead_provider_id

    {
      ect:,
      ect_at_school_period:,
      ect_training_period:,
      unfunded_mentor:,
      unfunded_mentor_at_school_period:,
      latest_mentorship_period:,
      lead_provider_id: effective_lead_provider_id
    }
  end

  let(:setup) { create_ect_and_unfunded_mentor_setup }
  let(:ect) { setup[:ect] }
  let(:ect_at_school_period) { setup[:ect_at_school_period] }
  let(:ect_training_period) { setup[:ect_training_period] }
  let(:unfunded_mentor) { setup[:unfunded_mentor] }
  let(:unfunded_mentor_at_school_period) { setup[:unfunded_mentor_at_school_period] }
  let(:latest_mentorship_period) { setup[:latest_mentorship_period] }
  let(:lead_provider_id) { setup[:lead_provider_id] }
  let(:query) { described_class.new(lead_provider_id:) }

  it_behaves_like "a query that avoids includes" do
    let(:params) { { lead_provider_id: } }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:latest_mentor_at_school_period)).to be_loaded }
    end

    describe "#unfunded_mentors" do
      subject(:result) do
        query.unfunded_mentors.first
      end

      include_context "preloaded associations"
    end

    describe "#unfunded_mentor_by_api_id" do
      subject(:result) { query.unfunded_mentor_by_api_id(unfunded_mentor.api_id) }

      include_context "preloaded associations"
    end

    describe "#unfunded_mentor_by_id" do
      subject(:result) { query.unfunded_mentor_by_id(unfunded_mentor.id) }

      include_context "preloaded associations"
    end
  end

  describe "#unfunded_mentors" do
    # Setup for the second unfunded mentor
    let!(:another_setup) do
      create_ect_and_unfunded_mentor_setup(lead_provider_id:)
    end
    let(:another_ect) { another_setup[:ect] }
    let(:another_unfunded_mentor) { another_setup[:unfunded_mentor] }
    let(:another_ect_at_school_period) { another_setup[:ect_at_school_period] }
    let(:another_unfunded_mentor_at_school_period) { another_setup[:unfunded_mentor_at_school_period] }
    let(:another_latest_mentorship_period) { another_setup[:latest_mentorship_period] }

    # Create a funded mentor to ensure it's excluded
    let(:funded_mentor) { FactoryBot.create(:teacher) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: funded_mentor, started_on: 2.months.ago) }
    let!(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period:) }

    describe "filtering" do
      describe "by `lead_provider`" do
        it "filters by `lead_provider`" do
          expect(query.unfunded_mentors).to contain_exactly(unfunded_mentor, another_unfunded_mentor)
        end

        it "returns empty if no unfunded mentors are found for the given `lead_provider`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.unfunded_mentors).to be_empty
        end

        it "returns empty if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.unfunded_mentors).to be_empty
        end

        it "returns empty if nil is supplied" do
          query = described_class.new(lead_provider_id: nil)

          expect(query.unfunded_mentors).to be_empty
        end
      end

      describe "by `updated_since`" do
        it "filters by `updated_since`" do
          another_unfunded_mentor.update!(api_updated_at: 3.days.ago)
          unfunded_mentor.update!(api_updated_at: 1.day.ago)

          query = described_class.new(lead_provider_id:, updated_since: 2.days.ago)

          expect(query.unfunded_mentors).to contain_exactly(unfunded_mentor)
        end

        it "does not filter by `updated_since` if omitted" do
          another_unfunded_mentor.update!(api_updated_at: 1.week.ago)
          unfunded_mentor.update!(api_updated_at: 2.weeks.ago)

          expect(query.unfunded_mentors).to contain_exactly(another_unfunded_mentor, unfunded_mentor)
        end

        it "does not filter by `updated_since` if blank" do
          another_unfunded_mentor.update!(api_updated_at: 1.week.ago)
          unfunded_mentor.update!(api_updated_at: 2.weeks.ago)

          query = described_class.new(lead_provider_id:, updated_since: " ")

          expect(query.unfunded_mentors).to contain_exactly(another_unfunded_mentor, unfunded_mentor)
        end
      end
    end

    describe "ordering" do
      before do
        unfunded_mentor.update!(created_at: 1.day.ago)
        another_unfunded_mentor.update!(created_at: 3.days.ago)
      end

      describe "default order" do
        it "returns unfunded mentors ordered by created_at, in ascending order" do
          expect(query.unfunded_mentors).to eq([another_unfunded_mentor, unfunded_mentor])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { created_at: :desc })
          expect(query.unfunded_mentors).to eq([unfunded_mentor, another_unfunded_mentor])
        end
      end

      describe "order by updated_at, in ascending order" do
        before { another_unfunded_mentor.update!(updated_at: 1.day.from_now) }

        it "returns unfunded mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { updated_at: :asc })
          expect(query.unfunded_mentors).to eq([unfunded_mentor, another_unfunded_mentor])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { updated_at: :desc })
          expect(query.unfunded_mentors).to eq([another_unfunded_mentor, unfunded_mentor])
        end
      end
    end
  end

  describe "#unfunded_mentor_by_api_id" do
    it "returns the unfunded mentor for a given id" do
      expect(query.unfunded_mentor_by_api_id(unfunded_mentor.api_id)).to eq(unfunded_mentor)
    end

    it "raises an error if the unfunded mentor does not exist" do
      expect { query.unfunded_mentor_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the unfunded mentor is not in the filtered query" do
      query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

      expect { query.unfunded_mentor_by_api_id(unfunded_mentor.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { query.unfunded_mentor_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#unfunded_mentor_by_id" do
    it "returns the unfunded mentor for a given id" do
      expect(query.unfunded_mentor_by_id(unfunded_mentor.id)).to eq(unfunded_mentor)
    end

    it "raises an error if the unfunded mentor does not exist" do
      expect { query.unfunded_mentor_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the unfunded mentor is not in the filtered query" do
      query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

      expect { query.unfunded_mentor_by_id(unfunded_mentor.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { query.unfunded_mentor_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
