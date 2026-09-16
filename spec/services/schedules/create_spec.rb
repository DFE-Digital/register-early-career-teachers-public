RSpec.describe Schedules::Create do
  subject(:service) { described_class.new(author:, contract_period_year:, identifier:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:contract_period_year) { contract_period.year }
  let(:identifier) { "ecf-standard-january" }
  let(:author) { Events::SystemAuthor.new }

  describe "#initialize" do
    it "accepts and assigns the author, contract period year, and identifier" do
      expect(service.author).to eq(author)
      expect(service.schedule).to be_a(Schedule)
      expect(service.schedule.contract_period_year).to eq(contract_period_year)
      expect(service.schedule.identifier).to eq(identifier)
    end
  end

  describe "#create!" do
    context "with valid params" do
      it "saves the schedule" do
        expect { service.create! }.to change(Schedule, :count).by(1)
      end

      it "returns the persisted schedule" do
        result = service.create!

        expect(result).to be_a(Schedule)
        expect(result).to be_persisted
        expect(service.schedule).to be(result)
      end

      it "records a schedule_added event" do
        service.create!

        event = Event.where(event_type: "schedule_added").sole
        expect(event.contract_period_id).to eq(service.schedule.contract_period.id)
        expect(event.heading).to include(service.schedule.description)
      end
    end

    context "with invalid params" do
      let(:identifier) { "invalid-identifier" }

      it "raises an error" do
        expect { service.create! }.to raise_error("Validation failed: Identifier Choose an identifier from the list")
        expect(Event.where(event_type: "schedule_added")).to be_empty
      end
    end

    context "when the identifier is already used for this contract period" do
      before do
        FactoryBot.create(:schedule, contract_period_year:, identifier:)
      end

      it "raises an error" do
        expect { service.create! }.to raise_error("Validation failed: Identifier Can be used once per contract period")
        expect(Event.where(event_type: "schedule_added")).to be_empty
      end
    end
  end
end
