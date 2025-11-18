describe API::Teachers::UnfundedMentorSerializer, type: :serializer do
  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(unfunded_mentor_teacher, **options))
  end

  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:created_at) { Time.utc(2023, 7, 1, 12, 0, 0) }
  let(:api_updated_at) { Time.utc(2023, 7, 2, 12, 0, 0) }
  let(:unfunded_mentor_teacher) do
    FactoryBot.create(
      :teacher,
      created_at:,
      api_updated_at:
    )
  end

  before do
    # Create mentor at school periods for the unfunded mentor teacher
    FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: unfunded_mentor_teacher, started_on: 6.months.ago, email: "test1@test.com")
    FactoryBot.create(:mentor_at_school_period, teacher: unfunded_mentor_teacher, started_on: 1.year.ago, finished_on: 6.months.ago, email: "test2@test.com")
  end

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to eq(unfunded_mentor_teacher.api_id)
      expect(response["type"]).to eq("unfunded-mentor")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["full_name"]).to be_present
      expect(attributes["full_name"]).to eq(Teachers::Name.new(unfunded_mentor_teacher).full_name_in_trs)
      expect(attributes["email"]).to be_present
      expect(attributes["email"]).to eq(unfunded_mentor_teacher.latest_mentor_at_school_period.email)
      expect(attributes["email"]).to eq("test1@test.com")
      expect(attributes["teacher_reference_number"]).to be_present
      expect(attributes["teacher_reference_number"]).to eq(unfunded_mentor_teacher.trn)
      expect(attributes["created_at"]).to be_present
      expect(attributes["created_at"]).to eq(created_at.utc.rfc3339)
      expect(attributes["updated_at"]).to be_present
      expect(attributes["updated_at"]).to eq(api_updated_at.utc.rfc3339)
    end
  end
end
