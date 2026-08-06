describe API::Teachers::MentoringMentorSerializer, type: :serializer do
  include MentorshipPeriodHelpers

  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(mentoring_mentor_teacher, **options))
  end

  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:created_at) { Time.utc(2023, 7, 1, 12, 0, 0) }
  let(:api_updated_at) { Time.utc(2023, 7, 2, 12, 0, 0) }
  let(:mentoring_mentor_teacher) do
    FactoryBot.create(
      :teacher,
      created_at:,
      api_updated_at:
    )
  end

  let!(:school_partnership_for_lead_provider) do
    FactoryBot.create(:school_partnership, :for_year, lead_provider:)
  end

  before do
    create_mentorship_period_for(
      mentee_school_partnership: school_partnership_for_lead_provider,
      mentor: mentoring_mentor_teacher,
      create_mentor_training_period: false,
      refresh_metadata: true
    )
    mentoring_mentor_teacher
      .mentor_at_school_periods
      .find_by(school: school_partnership_for_lead_provider.school)
      .update!(email: "lead-provider-school@example.com")
  end

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to eq(mentoring_mentor_teacher.api_id)
      expect(response["type"]).to eq("mentoring-mentor")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["email"]).to eq("lead-provider-school@example.com")
      expect(attributes["teacher_reference_number"]).to be_present
      expect(attributes["teacher_reference_number"]).to eq(mentoring_mentor_teacher.trn)
      expect(attributes["created_at"]).to be_present
      expect(attributes["created_at"]).to eq(created_at.utc.rfc3339)
      expect(attributes["updated_at"]).to be_present
      expect(attributes["updated_at"]).to eq(api_updated_at.utc.rfc3339)
    end

    describe "`full_name`" do
      subject(:full_name) { attributes["full_name"] }

      it { is_expected.to be_present }
      it { is_expected.to eq(Teachers::Name.new(mentoring_mentor_teacher).full_name) }

      context "when mentoring mentor teacher has a `corrected_name`" do
        let(:mentoring_mentor_teacher) { FactoryBot.create(:teacher, :with_corrected_name) }

        it { is_expected.to eq(mentoring_mentor_teacher.corrected_name) }
      end

      context "when mentoring mentor teacher has a `full_name_in_trs`" do
        let(:mentoring_mentor_teacher) { FactoryBot.create(:teacher, :with_realistic_name) }

        it { is_expected.to eq([mentoring_mentor_teacher.trs_first_name, mentoring_mentor_teacher.trs_last_name].join(" ")) }
      end
    end
  end

  describe "`email` per lead provider" do
    let!(:other_lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:school_partnership_for_other_lead_provider) do
      FactoryBot.create(
        :school_partnership,
        :for_year,
        lead_provider: other_lead_provider,
        year: school_partnership_for_lead_provider.lead_provider_delivery_partnership.active_lead_provider.contract_period_year
      )
    end

    before do
      create_mentorship_period_for(
        mentee_school_partnership: school_partnership_for_other_lead_provider,
        mentor: mentoring_mentor_teacher,
        create_mentor_training_period: false,
        refresh_metadata: true
      )
      mentoring_mentor_teacher
        .mentor_at_school_periods
        .find_by(school: school_partnership_for_other_lead_provider.school)
        .update!(email: "other-lead-provider-school@example.com")
    end

    it "returns the email from the school where the mentor mentors an ECT trained by the requesting lead provider" do
      response = JSON.parse(described_class.render(mentoring_mentor_teacher, lead_provider_id: lead_provider.id))
      expect(response.dig("attributes", "email")).to eq("lead-provider-school@example.com")
    end

    it "returns a different email when the same mentor is requested by another lead provider" do
      response = JSON.parse(described_class.render(mentoring_mentor_teacher, lead_provider_id: other_lead_provider.id))
      expect(response.dig("attributes", "email")).to eq("other-lead-provider-school@example.com")
    end
  end
end
