RSpec.describe API::Teachers::SchoolTransferSerializer, type: :serializer do
  include SchoolTransferHelpers

  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(teacher, **options))
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:other_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:leaving_training_period) do
    teacher.ect_at_school_periods.first.latest_training_period
  end
  let(:leaving_school) do
    teacher.ect_at_school_periods.first.school
  end
  let(:joining_training_period) do
    teacher.ect_at_school_periods.second.earliest_training_period
  end
  let(:joining_school) do
    teacher.ect_at_school_periods.second.school
  end

  describe "core attributes" do
    before do
      build_new_provider_transfer(teacher:, leaving_lead_provider: lead_provider, joining_lead_provider: other_lead_provider)
    end

    it "serializes correctly" do
      expect(response["id"]).to eq(teacher.api_id)
      expect(response["type"]).to eq("participant-transfer")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    context "when there is a transfer with both leaving and joining training periods" do
      before do
        build_new_provider_transfer(teacher:, leaving_lead_provider: lead_provider, joining_lead_provider: other_lead_provider)

        leaving_training_period.update!(api_transfer_updated_at: 3.days.ago)
        joining_training_period.update!(api_transfer_updated_at: 5.days.ago)
      end

      it "serializes correctly" do
        expect(attributes["updated_at"]).to eq(leaving_training_period.api_transfer_updated_at.utc.rfc3339)
        expect(attributes["transfers"].size).to eq(1)

        transfer = attributes["transfers"].first
        expect(transfer["training_record_id"]).to eq(teacher.api_ect_training_record_id)
        expect(transfer["transfer_type"]).to eq("new_provider")
        expect(transfer["status"]).to eq("complete")

        leaving = transfer["leaving"]
        expect(leaving["school_urn"]).to be_present
        expect(leaving["school_urn"]).to eq(leaving_school.urn)
        expect(leaving["provider"]).to be_present
        expect(leaving["provider"]).to eq(lead_provider.name)
        expect(leaving["date"]).to be_present
        expect(leaving["date"]).to eq(leaving_training_period.finished_on.rfc3339)
        joining = transfer["joining"]
        expect(joining["school_urn"]).to be_present
        expect(joining["school_urn"]).to eq(joining_school.urn)
        expect(joining["provider"]).to be_present
        expect(joining["provider"]).to eq(other_lead_provider.name)
        expect(joining["date"]).to be_present
        expect(joining["date"]).to eq(joining_training_period.finished_on.rfc3339)
      end
    end

    context "when there is a transfer with a school-led joining training period" do
      before do
        build_new_provider_transfer(teacher:, leaving_lead_provider: lead_provider)

        leaving_training_period.update!(api_transfer_updated_at: 3.days.ago)
        joining_training_period.update!(api_transfer_updated_at: 1.day.ago)
      end

      it "serializes correctly" do
        expect(attributes["updated_at"]).to eq(joining_training_period.api_transfer_updated_at.utc.rfc3339)
        expect(attributes["transfers"].size).to eq(1)

        transfer = attributes["transfers"].first
        expect(transfer["training_record_id"]).to eq(teacher.api_ect_training_record_id)
        expect(transfer["transfer_type"]).to eq("new_provider")
        expect(transfer["status"]).to eq("complete")

        leaving = transfer["leaving"]
        expect(leaving["school_urn"]).to be_present
        expect(leaving["school_urn"]).to eq(leaving_school.urn)
        expect(leaving["provider"]).to be_present
        expect(leaving["provider"]).to eq(lead_provider.name)
        expect(leaving["date"]).to be_present
        expect(leaving["date"]).to eq(leaving_training_period.finished_on.rfc3339)
        joining = transfer["joining"]
        expect(joining["school_urn"]).to be_present
        expect(joining["school_urn"]).to eq(joining_school.urn)
        expect(joining["provider"]).to be_nil
        expect(joining["date"]).to be_present
        expect(joining["date"]).to eq(joining_training_period.finished_on.rfc3339)
      end
    end

    context "when there is a transfer with an ongoing joining training period" do
      before do
        build_new_provider_transfer(teacher:, leaving_lead_provider: lead_provider)
        joining_training_period.update!(finished_on: nil, api_transfer_updated_at: 2.days.ago)
        leaving_training_period.update!(api_transfer_updated_at: 3.days.ago)
      end

      it "serializes correctly" do
        expect(attributes["updated_at"]).to eq(joining_training_period.api_transfer_updated_at.utc.rfc3339)
        expect(attributes["transfers"].size).to eq(1)

        transfer = attributes["transfers"].first
        expect(transfer["training_record_id"]).to eq(teacher.api_ect_training_record_id)
        expect(transfer["transfer_type"]).to eq("new_provider")
        expect(transfer["status"]).to eq("complete")

        leaving = transfer["leaving"]
        expect(leaving["school_urn"]).to be_present
        expect(leaving["school_urn"]).to eq(leaving_school.urn)
        expect(leaving["provider"]).to be_present
        expect(leaving["provider"]).to eq(lead_provider.name)
        expect(leaving["date"]).to be_present
        expect(leaving["date"]).to eq(leaving_training_period.finished_on.rfc3339)
        joining = transfer["joining"]
        expect(joining["school_urn"]).to be_present
        expect(joining["school_urn"]).to eq(joining_school.urn)
        expect(joining["provider"]).to be_nil
        expect(joining["date"]).to be_nil
      end
    end

    context "when there is a transfer without a joining_training_period" do
      before do
        build_unknown_transfer_for_finished_school_period(teacher:, lead_provider:)
        leaving_training_period.update!(api_transfer_updated_at: 3.days.ago)
      end

      it "serializes correctly" do
        expect(attributes["updated_at"]).to eq(leaving_training_period.api_transfer_updated_at.utc.rfc3339)
        expect(attributes["transfers"].size).to eq(1)

        transfer = attributes["transfers"].first
        expect(transfer["training_record_id"]).to eq(teacher.api_ect_training_record_id)
        expect(transfer["transfer_type"]).to eq("unknown")
        expect(transfer["status"]).to eq("complete")

        leaving = transfer["leaving"]
        expect(leaving["school_urn"]).to be_present
        expect(leaving["school_urn"]).to eq(leaving_school.urn)
        expect(leaving["provider"]).to be_present
        expect(leaving["provider"]).to eq(lead_provider.name)
        expect(leaving["date"]).to be_present
        expect(leaving["date"]).to eq(leaving_training_period.finished_on.rfc3339)
        joining = transfer["joining"]
        expect(joining).to be_nil
      end
    end
  end
end
