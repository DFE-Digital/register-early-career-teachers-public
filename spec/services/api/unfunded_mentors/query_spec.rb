RSpec.describe API::UnfundedMentors::Query, :with_metadata do
  it_behaves_like "a query that avoids includes" do
    before { FactoryBot.create(:mentor) }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:latest_mentor_at_school_period)).to be_loaded }
    end

    let(:instance) { described_class.new }
    let!(:mentor) { FactoryBot.create(:mentor) }

    describe "#unfunded_mentors" do
      subject(:result) do
        instance.unfunded_mentors.first
      end

      include_context "preloaded associations"
    end

    describe "#unfunded_mentor_by_api_id" do
      subject(:result) { instance.unfunded_mentor_by_api_id(mentor.api_id) }

      include_context "preloaded associations"
    end

    describe "#unfunded_mentor_by_id" do
      subject(:result) { instance.unfunded_mentor_by_id(mentor.id) }

      include_context "preloaded associations"
    end
  end

  describe "#unfunded_mentors" do
    it "returns all unfunded mentors" do
      mentors = FactoryBot.create_list(:mentor, 3)

      query = described_class.new

      expect(query.unfunded_mentors).to match_array(mentors)
    end

    it "orders unfunded mentors by created_at in ascending order" do
      mentor1 = travel_to(2.days.ago) { FactoryBot.create(:mentor) }
      mentor2 = travel_to(1.day.ago) { FactoryBot.create(:mentor) }
      mentor3 = FactoryBot.create(:mentor)

      query = described_class.new

      expect(query.unfunded_mentors).to eq([mentor1, mentor2, mentor3])
    end

    describe "filtering" do
      describe "by `lead_provider`" do
        let!(:ect) { FactoryBot.create(:teacher) }
        let!(:funded_mentor) { FactoryBot.create(:teacher) }
        let!(:unfunded_mentor) { FactoryBot.create(:teacher) }

        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: ect, started_on: 2.months.ago) }
        let!(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, ect_at_school_period:) }

        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: funded_mentor, started_on: 2.months.ago) }
        let!(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period:) }

        let(:other_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: unfunded_mentor, started_on: 2.months.ago) }
        let!(:other_mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period: other_mentor_at_school_period) }

        let!(:latest_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :ongoing,
            mentee: ect_at_school_period,
            mentor: other_mentor_at_school_period,
            started_on: ect_training_period.started_on + 1.week
          )
        end

        context "when `lead_provider` param is omitted" do
          it "returns all unfunded mentors" do
            expect(described_class.new.unfunded_mentors).to contain_exactly(funded_mentor, unfunded_mentor)
          end
        end

        it "filters by `lead_provider`" do
          lead_provider_id = ect.lead_provider_metadata.first.lead_provider_id
          query = described_class.new(lead_provider_id:)
          expect(query.unfunded_mentors).to contain_exactly(unfunded_mentor)
        end

        it "returns empty if no unfunded mentors are found for the given `lead_provider`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.unfunded_mentors).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.unfunded_mentors).to contain_exactly(funded_mentor, unfunded_mentor)
        end
      end

      describe "by `updated_since`" do
        it "filters by `updated_since`" do
          FactoryBot.create(:mentor).tap { it.update(api_updated_at: 2.days.ago) }
          mentor2 = FactoryBot.create(:mentor)

          query = described_class.new(updated_since: 1.day.ago)

          expect(query.unfunded_mentors).to contain_exactly(mentor2)
        end

        it "does not filter by `updated_since` if omitted" do
          mentor1 = FactoryBot.create(:mentor).tap { it.update(api_updated_at: 1.week.ago) }
          mentor2 = FactoryBot.create(:mentor).tap { it.update(api_updated_at: 2.weeks.ago) }

          expect(described_class.new.unfunded_mentors).to contain_exactly(mentor1, mentor2)
        end

        it "does not filter by `updated_since` if blank" do
          mentor1 = FactoryBot.create(:mentor).tap { it.update(api_updated_at: 1.week.ago) }
          mentor2 = FactoryBot.create(:mentor).tap { it.update(api_updated_at: 2.weeks.ago) }

          query = described_class.new(updated_since: " ")

          expect(query.unfunded_mentors).to contain_exactly(mentor1, mentor2)
        end
      end
    end

    describe "ordering" do
      let!(:mentor1) { FactoryBot.create(:mentor) }
      let!(:mentor2) { travel_to(1.day.ago) { FactoryBot.create(:mentor) } }

      describe "default order" do
        it "returns unfunded mentors ordered by created_at, in ascending order" do
          query = described_class.new
          expect(query.unfunded_mentors).to eq([mentor2, mentor1])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(sort: { created_at: :desc })
          expect(query.unfunded_mentors).to eq([mentor1, mentor2])
        end
      end

      describe "order by updated_at, in ascending order" do
        before { mentor2.update!(updated_at: 1.day.from_now) }

        it "returns unfunded mentors in correct order" do
          query = described_class.new(sort: { updated_at: :asc })
          expect(query.unfunded_mentors).to eq([mentor1, mentor2])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns unfunded mentors in correct order" do
          query = described_class.new(sort: { updated_at: :desc })
          expect(query.unfunded_mentors).to eq([mentor1, mentor2])
        end
      end
    end
  end

  describe "#unfunded_mentor_by_api_id" do
    it "returns the unfunded mentor for a given id" do
      mentor = FactoryBot.create(:mentor)
      query = described_class.new

      expect(query.unfunded_mentor_by_api_id(mentor.api_id)).to eq(mentor)
    end

    it "raises an error if the unfunded mentor does not exist" do
      query = described_class.new

      expect { query.unfunded_mentor_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the unfunded mentor is not in the filtered query" do
      mentor = FactoryBot.create(:mentor)

      query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

      expect { query.unfunded_mentor_by_api_id(mentor.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new.unfunded_mentor_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#unfunded_mentor_by_id" do
    it "returns the unfunded mentor for a given id" do
      mentor = FactoryBot.create(:mentor)
      query = described_class.new

      expect(query.unfunded_mentor_by_id(mentor.id)).to eq(mentor)
    end

    it "raises an error if the unfunded mentor does not exist" do
      query = described_class.new

      expect { query.unfunded_mentor_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the unfunded mentor is not in the filtered query" do
      mentor = FactoryBot.create(:mentor)

      query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

      expect { query.unfunded_mentor_by_id(mentor.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { described_class.new.unfunded_mentor_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
