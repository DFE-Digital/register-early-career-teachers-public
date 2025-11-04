RSpec.describe Schedules::Assignment do
  include ActiveJob::TestHelper

  
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:active_lead_provider) { FactoryBot.build(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.build(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.build(:school_partnership, lead_provider_delivery_partnership:, school: ect_at_school_period.school) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
  let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }
  let(:year) { Date.current.year }
  let(:contract_period) { FactoryBot.create(:contract_period, year:, started_on: 1.month.ago, finished_on: 1.month.from_now) }
  let(:schedule) { FactoryBot.build(:schedule, contract_period: ) }

  describe '#for_ects' do
    subject(:service) do
      described_class.for_ects(ect_at_school_period:)
    end

    it 'assigns a schedule to the current training period' do
      service
      expect(training_period.schedule).to eq(schedule)
    end
  end



end
