RSpec.describe TrainingPeriods::Create do
  subject(:result) do
    described_class.new(
      period:,
      started_on:,
      school_partnership:,
      expression_of_interest:,
      training_programme:,
      finished_on:
    ).call
  end

  let(:started_on) { Time.zone.today - 1.month }
  let(:year) { Date.current.year }
  let(:contract_period) { FactoryBot.create(:contract_period, year:) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school) { FactoryBot.create(:school) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }
  let(:expression_of_interest) { nil }
  let(:training_programme) { 'provider_led' }
  let(:finished_on) { Time.zone.today - 3.weeks }
  # let!(:schedule) { FactoryBot.create(:schedule, contract_period: school_partnership.contract_period) }

  before do
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-april")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
  end

  context 'with an ECTAtSchoolPeriod' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: started_on - 2.weeks,
        finished_on: started_on + 2.weeks
      )
    end

    it 'creates a TrainingPeriod associated with the ECTAtSchoolPeriod' do
      expect { result }.to change(TrainingPeriod, :count).by(1)

      training_period = result
      expect(training_period.ect_at_school_period).to eq(period)
      expect(training_period.mentor_at_school_period).to be_nil
      expect(training_period.started_on).to eq(started_on)
      expect(training_period.school_partnership).to eq(school_partnership)
      expect(training_period.expression_of_interest).to eq(expression_of_interest)
      expect(training_period.finished_on).to eq(finished_on)
      expect(training_period.schedule).to eq(schedule)
    end
  end

  context 'with a MentorAtSchoolPeriod' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:period) do
      FactoryBot.create(
        :mentor_at_school_period,
        teacher:,
        started_on: started_on - 1.month,
        finished_on: started_on + 1.month
      )
    end

    it 'creates a TrainingPeriod associated with the MentorAtSchoolPeriod' do
      expect { result }.to change(TrainingPeriod, :count).by(1)

      training_period = result
      expect(training_period.mentor_at_school_period).to eq(period)
      expect(training_period.ect_at_school_period).to be_nil
      expect(training_period.started_on).to eq(started_on)
      expect(training_period.school_partnership).to eq(school_partnership)
      expect(training_period.expression_of_interest).to eq(expression_of_interest)
      expect(training_period.finished_on).to eq(finished_on)
      expect(training_period.schedule).to eq(schedule)
    end
  end

  context "with unsupported period type" do
    let(:period) { double("UnknownPeriod") }

    it "raises an ArgumentError" do
      expect {
        result
      }.to raise_error(ArgumentError, /Unsupported period type/)
    end
  end

  describe '.school_led' do
    let(:period) { FactoryBot.create(:ect_at_school_period) }

    it 'calls new with the school_led arguments' do
      allow(TrainingPeriods::Create).to receive(:new).and_return(true)

      TrainingPeriods::Create.school_led(period:, started_on:)

      expect(TrainingPeriods::Create).to have_received(:new).with(period:, started_on:, training_programme: 'school_led')
    end
  end

  describe '.provider_led' do
    let(:period) { FactoryBot.create(:ect_at_school_period) }

    it 'calls new with the provider_led arguments' do
      allow(TrainingPeriods::Create).to receive(:new).with(any_args).and_call_original

      TrainingPeriods::Create.provider_led(period:, started_on:, school_partnership:, expression_of_interest:, finished_on:)

      expect(TrainingPeriods::Create).to have_received(:new).with(
        period:,
        started_on:,
        school_partnership:,
        expression_of_interest:,
        training_programme: 'provider_led',
        finished_on:
      )
    end
  end
end
