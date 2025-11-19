RSpec.describe Auditable do
  let(:auditable_service) do
    Class.new do
      def self.name = "AuditableService"
      include Auditable
    end
  end

  let(:author) { FactoryBot.create(:dfe_user) }

  it "defines expected auditable params" do
    expect(auditable_service.auditable_params).to eq({
      "auditable_service" => %i[zendesk_ticket_id note]
    })
  end

  context "without arguments" do
    subject(:service) { auditable_service.new }

    it do
      expect(service).to be_invalid
      expect(service.errors.messages).to eq({ author: ["can't be blank"] })
    end
  end

  context "with author" do
    subject(:service) do
      auditable_service.new(author:)
    end

    it "requires either a note or support ticket" do
      expect(service).to be_invalid
      expect(service.errors.messages).to eq({ base: ["Add a note or enter the Zendesk ticket number"] })
    end
  end

  describe "#note" do
    subject(:service) do
      auditable_service.new(author:, note: "Context message")
    end

    it "saves the note" do
      expect(service).to be_valid
      expect(service.author).to eq(author)
      expect(service.note).to eq("Context message")
    end
  end

  describe "#zendesk_ticket_id" do
    subject(:service) do
      auditable_service.new(author:, zendesk_ticket_id: "#123456")
    end

    it "saves the normalized ticket number" do
      expect(service).to be_valid
      expect(service.zendesk_ticket_id).to eq("123456")
    end
  end
end
