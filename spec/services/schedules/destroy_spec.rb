RSpec.describe Schedules::Destroy do
  subject(:service) { described_class.new(author:, schedule:) }

  let(:author) { Events::SystemAuthor.new }
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let!(:schedule) { FactoryBot.create(:schedule, contract_period:) }

  describe "#destroy!" do
    before do
      allow(Events::Record).to receive(:record_schedule_deleted_event!)
    end

    it "destroys the schedule" do
      expect { service.destroy! }.to change(Schedule, :count).by(-1)
    end

    it "records a schedule_deleted event" do
      service.destroy!

      expect(Events::Record).to have_received(:record_schedule_deleted_event!).with(
        author:,
        schedule:
      )
    end

    context "when the schedule has milestones" do
      before do
        FactoryBot.create(:milestone, schedule:)
      end

      it "raises an error and does not delete the schedule" do
        expect { service.destroy! }
          .to raise_error(ActiveRecord::InvalidForeignKey)
          .and(not_change(Schedule, :count))
      end
    end
  end
end
