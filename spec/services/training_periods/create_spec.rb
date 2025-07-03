RSpec.describe TrainingPeriods::Create do
  subject(:result) do
    described_class.new(
      period:,
      started_on:,
      school_partnership:,
      expression_of_interest:
    ).call
  end

  let(:started_on) { Time.zone.today - 1.month }
  let(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:expression_of_interest) { nil }

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
end
