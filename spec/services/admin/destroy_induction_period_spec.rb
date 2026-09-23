RSpec.describe Admin::DestroyInductionPeriod do
  subject(:service) do
    described_class.new(
      author:,
      induction_period:
    )
  end

  include_context "test TRS API returns a teacher"
  include ActiveJob::TestHelper

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body_period:) }

  describe "#destroy_induction_period!" do
    it "destroys the induction period" do
      expect { service.destroy_induction_period! }.to change(InductionPeriod, :count).by(-1)
    end

    it "records an event with the correct parameters" do
      service.destroy_induction_period!

      event = Event.where(event_type: "induction_period_deleted").sole
      expect(event).to have_attributes(
        teacher_id: teacher.id,
        appropriate_body_period_id: appropriate_body_period.id
      )
      expect(event.modifications).to be_present
    end
  end
end
