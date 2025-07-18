RSpec.describe LeadProvider, type: :validator do
  subject { model_class.new(lead_provider_id:) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :lead_provider_id

      validates :lead_provider_id, lead_provider: true
    end
  end

  context "when lead_provider_id is nil" do
    let(:lead_provider_id) { nil }

    it "does not add an error" do
      expect(subject.valid?).to be(true)
      expect(subject.errors[:lead_provider_id]).to be_empty
    end
  end

  context "when lead_provider_id is valid" do
    let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

    it "does not add an error" do
      expect(subject.valid?).to be(true)
      expect(subject.errors[:lead_provider_id]).to be_empty
    end
  end

  context "when lead_provider_id is invalid" do
    let(:lead_provider_id) { 9999 }

    it "adds a default error message" do
      expect(subject.valid?).to be(false)
      expect(subject.errors[:lead_provider_id]).to include("Enter the name of a known lead provider")
    end
  end

  context "with a custom error message" do
    let(:lead_provider_id) { 9999 }
    let(:model_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :lead_provider_id

        validates :lead_provider_id, lead_provider: { message: "custom validation message" }
      end
    end

    it "uses the custom message" do
      expect(subject.valid?).to be(false)
      expect(subject.errors[:lead_provider_id]).to include("custom validation message")
    end
  end
end
