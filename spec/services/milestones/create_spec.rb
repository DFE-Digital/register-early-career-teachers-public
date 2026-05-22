RSpec.describe Milestones::Create do
  subject(:service) { described_class.new(author:, schedule:, params:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
  let(:author) { Events::SystemAuthor.new }
  let(:params) do
    {
      declaration_type: "started",
      start_date: Date.new(2026, 1, 1),
      milestone_date: Date.new(2026, 6, 1),
    }
  end

  describe "#create!" do
    before do
      allow(Events::Record).to receive(:record_milestone_added_event!)
    end

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

        expect(Events::Record).to have_received(:record_milestone_added_event!).with(
          author:,
          milestone: service.milestone
        )
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

      it { expect(service.create!).to be(false) }

      it "does not save the milestone" do
        expect { service.create! }.not_to change(Milestone, :count)

        expect(service.milestone).not_to be_persisted
        expect(service.milestone.errors[:declaration_type]).to include("Choose a valid declaration type")
        expect(service.milestone.errors[:start_date]).to include("Enter a start date")
      end

      it "does not record an event" do
        service.create!

        expect(Events::Record).not_to have_received(:record_milestone_added_event!)
      end
    end

    context "when the declaration type is already used for this schedule" do
      before do
        FactoryBot.create(:milestone, schedule:, declaration_type: "started")
      end

      it { expect(service.create!).to be(false) }

      it "does not save the milestone" do
        expect { service.create! }.not_to change(Milestone, :count)

        expect(service.milestone).not_to be_persisted
        expect(service.milestone.errors[:declaration_type]).to include("Can be used once per schedule")
      end

      it "does not record an event" do
        service.create!

        expect(Events::Record).not_to have_received(:record_milestone_added_event!)
      end
    end

    context "when the milestone date is before the start date" do
      let(:params) do
        {
          declaration_type: "retained-1",
          start_date: Date.new(2026, 6, 1),
          milestone_date: Date.new(2026, 1, 1),
        }
      end

      it { expect(service.create!).to be(false) }

      it "does not save the milestone" do
        expect { service.create! }.not_to change(Milestone, :count)

        expect(service.milestone).not_to be_persisted
        expect(service.milestone.errors[:milestone_date]).to include("Milestone date must be after the start date")
      end
    end
  end
end
