RSpec.describe API::Teachers::MentoringMentors::Query, :with_metadata do
  include MentorshipPeriodHelpers

  let(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:lead_provider_id) { school_partnership.lead_provider.id }
  let(:query) { described_class.new(lead_provider_id:) }

  let!(:mentoring_mentor) do
    mentor_school_partnership = other_lp_school_partnership_for(school_partnership:)

    create_mentorship_period_for(
      mentee_school_partnership: school_partnership,
      mentor_school_partnership:,
      refresh_metadata: true
    ).mentor.teacher
  end

  def other_lp_school_partnership_for(school_partnership:)
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: school_partnership.lead_provider_delivery_partnership.active_lead_provider.contract_period_year,
      school: school_partnership.school
    )
  end

  it_behaves_like "a query that avoids includes" do
    let(:params) { { lead_provider_id: } }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:lead_provider_metadata_for_mentees)).to be_loaded }
    end

    describe "#mentoring_mentors" do
      subject(:result) { query.mentoring_mentors.first }

      include_context "preloaded associations"
    end

    describe "#mentoring_mentor_by_api_id" do
      subject(:result) { query.mentoring_mentor_by_api_id(mentoring_mentor.api_id) }

      include_context "preloaded associations"
    end

    describe "#mentoring_mentor_by_id" do
      subject(:result) { query.mentoring_mentor_by_id(mentoring_mentor.id) }

      include_context "preloaded associations"
    end
  end

  describe "#mentoring_mentors" do
    describe "filtering" do
      describe "by `lead_provider`" do
        let!(:other_mentoring_mentor) do
          mentor_school_partnership = other_lp_school_partnership_for(school_partnership:)

          create_mentorship_period_for(
            mentee_school_partnership: school_partnership,
            mentor_school_partnership:,
            refresh_metadata: true
          ).mentor.teacher
        end

        before do
          # Mentor associated with the lead provider but not mentoring an ECT training with the provider
          create_mentorship_period_for(
            mentee_school_partnership: other_lp_school_partnership_for(school_partnership:),
            mentor_school_partnership: school_partnership,
            refresh_metadata: true
          )

          # Mentor for another lead provider (should be ignored)
          other_school_partnership = FactoryBot.create(:school_partnership)
          mentor_school_partnership = other_lp_school_partnership_for(school_partnership: other_school_partnership)

          create_mentorship_period_for(
            mentee_school_partnership: other_school_partnership,
            mentor_school_partnership:,
            refresh_metadata: true
          )
        end

        it "filters by `lead_provider`" do
          expect(query.mentoring_mentors).to contain_exactly(mentoring_mentor, other_mentoring_mentor)
        end

        it "returns empty if no mentoring mentors are found for the given `lead_provider`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.mentoring_mentors).to be_empty
        end

        it "returns empty if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.mentoring_mentors).to be_empty
        end

        it "returns empty if nil is supplied" do
          query = described_class.new(lead_provider_id: nil)

          expect(query.mentoring_mentors).to be_empty
        end
      end

      describe "by `updated_since`" do
        let!(:other_mentoring_mentor) do
          mentor_school_partnership = other_lp_school_partnership_for(school_partnership:)

          create_mentorship_period_for(
            mentee_school_partnership: school_partnership,
            mentor_school_partnership:,
            refresh_metadata: true
          ).mentor.teacher
        end

        before do
          mentoring_mentor.update!(api_updated_at: 3.days.ago)
          other_mentoring_mentor.update!(api_updated_at: 1.day.ago)
        end

        it "filters by `updated_since`" do
          query = described_class.new(lead_provider_id:, updated_since: 2.days.ago)

          expect(query.mentoring_mentors).to contain_exactly(other_mentoring_mentor)
        end

        it "does not filter by `updated_since` if omitted" do
          expect(query.mentoring_mentors).to contain_exactly(other_mentoring_mentor, mentoring_mentor)
        end

        it "does not filter by `updated_since` if blank" do
          query = described_class.new(lead_provider_id:, updated_since: " ")

          expect(query.mentoring_mentors).to contain_exactly(other_mentoring_mentor, mentoring_mentor)
        end
      end
    end

    describe "ordering" do
      let!(:other_mentoring_mentor) do
        mentor_school_partnership = other_lp_school_partnership_for(school_partnership:)

        create_mentorship_period_for(
          mentee_school_partnership: school_partnership,
          mentor_school_partnership:,
          refresh_metadata: true
        ).mentor.teacher
      end

      before do
        mentoring_mentor.update!(api_updated_at: 1.day.ago)
        other_mentoring_mentor.update!(api_updated_at: 4.days.ago)
      end

      describe "default order" do
        it "returns mentoring mentors ordered by created_at, in ascending order" do
          expect(query.mentoring_mentors).to eq([mentoring_mentor, other_mentoring_mentor])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns mentoring mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { created_at: :desc })
          expect(query.mentoring_mentors).to eq([other_mentoring_mentor, mentoring_mentor])
        end
      end

      describe "order by updated_at, in ascending order" do
        it "returns mentoring mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { api_updated_at: :asc })
          expect(query.mentoring_mentors).to eq([other_mentoring_mentor, mentoring_mentor])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns mentoring mentors in correct order" do
          query = described_class.new(lead_provider_id:, sort: { api_updated_at: :desc })
          expect(query.mentoring_mentors).to eq([mentoring_mentor, other_mentoring_mentor])
        end
      end
    end
  end

  describe "#mentoring_mentor_by_api_id" do
    it "returns the mentoring mentor for a given id" do
      expect(query.mentoring_mentor_by_api_id(mentoring_mentor.api_id)).to eq(mentoring_mentor)
    end

    it "raises an error if the mentoring mentor does not exist" do
      expect { query.mentoring_mentor_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the mentoring mentor is not in the filtered query" do
      query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

      expect { query.mentoring_mentor_by_api_id(mentoring_mentor.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { query.mentoring_mentor_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#mentoring_mentor_by_id" do
    it "returns the mentoring mentor for a given id" do
      expect(query.mentoring_mentor_by_id(mentoring_mentor.id)).to eq(mentoring_mentor)
    end

    it "raises an error if the mentoring mentor does not exist" do
      expect { query.mentoring_mentor_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the mentoring mentor is not in the filtered query" do
      query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

      expect { query.mentoring_mentor_by_id(mentoring_mentor.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { query.mentoring_mentor_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
