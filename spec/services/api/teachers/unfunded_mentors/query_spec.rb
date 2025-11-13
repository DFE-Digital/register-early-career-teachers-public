RSpec.describe API::Teachers::UnfundedMentors::Query, :with_metadata do
  def create_mentorship_period(mentor_school_partnership:, mentee_school_partnership:)
    mentee = FactoryBot.create(:teacher)
    mentee_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, teacher: mentee, started_on: 2.months.ago)
    FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, ect_at_school_period: mentee_school_period, school_partnership: mentee_school_partnership)

    unfunded_mentor = FactoryBot.create(:teacher)
    unfunded_mentor_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: unfunded_mentor, started_on: 2.months.ago)
    FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period: unfunded_mentor_school_period, school_partnership: mentor_school_partnership)

    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: mentee_school_period,
      mentor: unfunded_mentor_school_period
    )
  end

  let(:lead_provider_id) { school_partnership.lead_provider.id }
  let(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:other_school_partnership) { FactoryBot.create(:school_partnership) }
  let!(:unfunded_mentor) { create_mentorship_period(mentor_school_partnership: other_school_partnership, mentee_school_partnership: school_partnership).mentor.teacher }
  let(:query) { described_class.new(lead_provider_id:) }

  it_behaves_like "a query that avoids includes" do
    let(:params) { { lead_provider_id: } }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:latest_mentor_at_school_period)).to be_loaded }
    end

    describe "#unfunded_mentors" do
      subject(:result) { query.unfunded_mentors.first }

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
    describe "filtering" do
      describe "by `lead_provider`" do
        let!(:other_unfunded_mentor) { create_mentorship_period(mentor_school_partnership: other_school_partnership, mentee_school_partnership: school_partnership).mentor.teacher }

        before do
          # Mentor associated with the lead provider (so not unfunded and should be ignored)
          create_mentorship_period(mentor_school_partnership: school_partnership, mentee_school_partnership: school_partnership)
          # Unfunded mentor for another lead provider (should be ignored)
          create_mentorship_period(mentor_school_partnership: other_school_partnership, mentee_school_partnership: other_school_partnership)
        end

        it "filters by `lead_provider`" do
          expect(query.unfunded_mentors).to contain_exactly(unfunded_mentor, other_unfunded_mentor)
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
        let!(:other_unfunded_mentor) { create_mentorship_period(mentor_school_partnership: other_school_partnership, mentee_school_partnership: school_partnership).mentor.teacher }

        before do
          unfunded_mentor.update!(api_updated_at: 3.days.ago)
          other_unfunded_mentor.update!(api_updated_at: 1.day.ago)
        end

        it "filters by `updated_since`" do
          query = described_class.new(lead_provider_id:, updated_since: 2.days.ago)

          expect(query.unfunded_mentors).to contain_exactly(other_unfunded_mentor)
        end

        it "does not filter by `updated_since` if omitted" do
          expect(query.unfunded_mentors).to contain_exactly(other_unfunded_mentor, unfunded_mentor)
        end

        it "does not filter by `updated_since` if blank" do
          query = described_class.new(lead_provider_id:, updated_since: " ")

          expect(query.unfunded_mentors).to contain_exactly(other_unfunded_mentor, unfunded_mentor)
        end
      end
    end

    describe "ordering" do
      let!(:other_unfunded_mentor) { create_mentorship_period(mentor_school_partnership: other_school_partnership, mentee_school_partnership: school_partnership).mentor.teacher }

      before do
        unfunded_mentor.update!(api_updated_at: 1.day.ago)
        other_unfunded_mentor.update!(api_updated_at: 4.days.ago)
      end

      describe "default order" do
        it "returns unfunded mentors ordered by created_at, in ascending order" do
          expect(query.unfunded_mentors).to eq([unfunded_mentor, other_unfunded_mentor])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { created_at: :desc })
          expect(query.unfunded_mentors).to eq([other_unfunded_mentor, unfunded_mentor])
        end
      end

      describe "order by updated_at, in ascending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { api_updated_at: :asc })
          expect(query.unfunded_mentors).to eq([other_unfunded_mentor, unfunded_mentor])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { api_updated_at: :desc })
          expect(query.unfunded_mentors).to eq([unfunded_mentor, other_unfunded_mentor])
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
