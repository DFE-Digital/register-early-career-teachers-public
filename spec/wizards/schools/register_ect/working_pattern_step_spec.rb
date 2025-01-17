require 'rails_helper'

RSpec.describe Schools::RegisterECTWizard::WorkingPatternStep, type: :model do
  describe 'validations' do
    subject { described_class.new(working_pattern:) }

    context 'when the working_pattern is not present' do
      let(:working_pattern) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:working_pattern]).to include("Select if the ECT's working pattern is full or part time")
      end
    end

    context 'when the working_pattern is has an unknown value' do
      let(:working_pattern) { 'unknown_working_pattern' }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:working_pattern]).to include("'unknown_working_pattern' is not a valid working pattern")
      end
    end

    context 'when the working_pattern is present and a known value' do
      let(:working_pattern) { 'part_time' }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#previous_step' do
    let(:school) { FactoryBot.build(:school) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :working_pattern, school:) }

    subject { wizard.current_step }

    it 'returns the next step' do
      expect(subject.previous_step).to eq(:start_date)
    end
  end

  describe '#next_step' do
    let(:school) { FactoryBot.build(:school) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :working_pattern, school:) }

    subject { wizard.current_step }

    context 'when the school is independent' do
      before do
        allow(school).to receive(:independent?).and_return(true)
      end

      it 'returns :independent_school_appropriate_body' do
        expect(subject.next_step).to eq(:independent_school_appropriate_body)
      end
    end

    context 'when the school is state-funded' do
      before do
        allow(school).to receive(:independent?).and_return(false)
      end

      it 'returns :state_school_appropriate_body' do
        expect(subject.next_step).to eq(:state_school_appropriate_body)
      end
    end
  end

  context '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "working_pattern" => {
          "working_pattern" => 'part_time',
        }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :working_pattern, step_params:) }

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :working_pattern)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect working pattern' do
        expect { subject.save! }
          .to change(subject.ect, :working_pattern).from(nil).to('part_time')
      end
    end
  end
end
