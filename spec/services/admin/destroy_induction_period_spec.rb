RSpec.describe Admin::DestroyInductionPeriod do
  subject(:service) do
    described_class.new(
      author:,
      induction_period:
    )
  end

  include_context 'fake trs api client'
  include ActiveJob::TestHelper

  before do
    allow(Events::Record).to receive(:record_induction_period_deleted_event!).and_return(true)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { FactoryBot.create(:user) }
  let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body:) }

  describe "#destroy_induction_period!" do
    it "destroys the induction period" do
      expect { service.destroy_induction_period! }.to change(InductionPeriod, :count).by(-1)
    end

    it "records an event with the correct parameters" do
      expect(Events::Record).to receive(:record_induction_period_deleted_event!).with(
        author:,
        teacher:,
        appropriate_body:,
        modifications: induction_period.attributes
      )
      service.destroy_induction_period!
    end
  end
end
