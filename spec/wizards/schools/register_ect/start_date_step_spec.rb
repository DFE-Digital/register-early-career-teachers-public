require 'rails_helper'

RSpec.describe Schools::RegisterECTWizard::StartDateStep, type: :model do
  describe 'validations' do
    subject { described_class.new(start_date:) }

    context 'when the start_date is not present' do
      let(:start_date) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:start_date]).to include("Enter the date the ECT started or will start teaching at your school")
      end
    end

    context 'when the start_date is present and valid' do
      let(:start_date) { { 1 => "2024", 2 => "07" } }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#next_step' do
    let(:school) { FactoryBot.build(:school) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :start_date, school:) }

    subject { wizard.current_step }

    it 'returns the next step' do
      expect(subject.next_step).to eq(:working_pattern)
    end
  end

  describe '#previous_step' do
    let(:school) { FactoryBot.build(:school) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :start_date, school:) }

    subject { wizard.current_step }

    it 'returns the previous step' do
      expect(subject.previous_step).to eq(:email_address)
    end
  end

  context '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "start_date" => { "start_date(1i)" => "2024", "start_date(2i)" => "07" }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :start_date, step_params:) }

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :start_date)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect start date' do
        expect { subject.save! }
          .to change(subject.ect, :start_date).from(nil).to('July 2024')
      end
    end
  end
end
