RSpec.describe Milestones::Destroy do
  subject(:service) { described_class.new(author:, milestone:) }

  let(:author) { Events::SystemAuthor.new }
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
  let!(:milestone) { FactoryBot.create(:milestone, schedule:) }

  describe "#destroy!" do
    before do
      allow(Events::Record).to receive(:record_milestone_deleted_event!)
    end

    it "destroys the milestone" do
      expect { service.destroy! }.to change(Milestone, :count).by(-1)
    end

    it "records a milestone_deleted event" do
      service.destroy!

      expect(Events::Record).to have_received(:record_milestone_deleted_event!).with(
        author:,
        milestone:
      )
    end
  end
end
