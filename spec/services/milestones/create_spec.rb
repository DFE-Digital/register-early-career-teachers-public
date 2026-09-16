RSpec.describe Milestones::Create do
  subject(:service) { described_class.new(author:, schedule:, params:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
  let(:author) { Events::SystemAuthor.new }
  let(:params) do
    {
      declaration_type: "started",
      start_date: Date.new(contract_period.year, 6, 1),
      milestone_date: Date.new(contract_period.year, 9, 1),
    }
  end

  describe "#create!" do
    context "with valid params" do
      it "saves the milestone" do
        expect { service.create! }.to change(Milestone, :count).by(1)
      end

      it "returns the persisted milestone" do
        result = service.create!

        expect(result).to be_a(Milestone)
        expect(result).to be_persisted
        expect(service.milestone).to be(result)
      end

      it "records a milestone_added event" do
        service.create!

        event = Event.where(event_type: "milestone_added").sole
        expect(event.contract_period_id).to eq(contract_period.id)
        expect(event.heading).to include(service.milestone.declaration_type.titleize, schedule.description)
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          declaration_type: "invalid-declaration",
          start_date: nil,
          milestone_date: nil,
        }
      end

      it "raises an error" do
        expect { service.create! }.to raise_error(/Declaration type Choose a valid declaration type/)
        expect(Event.where(event_type: "milestone_added")).to be_empty
      end
    end

    context "when the declaration type is already used for this schedule" do
      before do
        FactoryBot.create(:milestone, schedule:, declaration_type: "started")
      end

      it "raises an error" do
        expect { service.create! }.to raise_error(/Declaration type Can be used once per schedule/)
        expect(Event.where(event_type: "milestone_added")).to be_empty
      end
    end

    context "when the milestone date is before the start date" do
      let(:params) do
        {
          declaration_type: "retained-1",
          start_date: Date.new(contract_period.year, 6, 1),
          milestone_date: Date.new(contract_period.year, 1, 1),
        }
      end

      it "raises an error" do
        expect { service.create! }.to raise_error(/Milestone date Milestone date must be after the start date/)
        expect(Event.where(event_type: "milestone_added")).to be_empty
      end
    end
  end
end
