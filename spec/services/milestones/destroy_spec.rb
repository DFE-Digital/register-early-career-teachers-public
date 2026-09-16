RSpec.describe Milestones::Destroy do
  subject(:service) { described_class.new(author:, milestone:) }

  let(:author) { Events::SystemAuthor.new }
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
  let!(:milestone) { FactoryBot.create(:milestone, schedule:) }

  describe "#destroy!" do
    it "destroys the milestone" do
      expect { service.destroy! }.to change(Milestone, :count).by(-1)
    end

    it "records a milestone_deleted event" do
      service.destroy!

      event = Event.where(event_type: "milestone_deleted").sole
      expect(event.contract_period_id).to eq(schedule.contract_period.id)
      expect(event.heading).to include(milestone.declaration_type.titleize, schedule.description)
    end
  end
end
