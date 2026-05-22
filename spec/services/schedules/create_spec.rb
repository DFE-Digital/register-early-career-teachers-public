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
    before do
      allow(Events::Record).to receive(:record_schedule_added_event!)
    end

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

        expect(Events::Record).to have_received(:record_schedule_added_event!).with(
          author:,
          schedule: service.schedule
        )
      end
    end

    context "with invalid params" do
      let(:identifier) { "invalid-identifier" }

      it { expect(service.create!).to be(false) }

      it "does not save the schedule" do
        expect { service.create! }.not_to change(Schedule, :count)

        expect(service.schedule).not_to be_persisted
        expect(service.schedule.errors[:identifier]).to include("Choose an identifier from the list")
      end

      it "does not record an event" do
        service.create!

        expect(Events::Record).not_to have_received(:record_schedule_added_event!)
      end
    end

    context "when the identifier is already used for this contract period" do
      before do
        FactoryBot.create(:schedule, contract_period_year:, identifier:)
      end

      it { expect(service.create!).to be(false) }

      it "does not save the schedule" do
        expect { service.create! }.not_to change(Schedule, :count)

        expect(service.schedule).not_to be_persisted
        expect(service.schedule.errors[:identifier]).to include("Can be used once per contract period")
      end

      it "does not record an event" do
        service.create!

        expect(Events::Record).not_to have_received(:record_schedule_added_event!)
      end
    end
  end
end
