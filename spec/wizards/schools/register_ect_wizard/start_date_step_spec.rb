RSpec.describe Schools::RegisterECTWizard::StartDateStep, type: :model do
  subject { wizard.current_step }

  let(:prepopulated_start_date) { { "1" => "2025", "2" => "01" } }
  let(:provided_start_date) { { "1" => "2024", "2" => "12" } }
  let(:school) { FactoryBot.build(:school) }
  let(:step_params) { {} }
  let(:store) { FactoryBot.build(:session_repository, start_date: prepopulated_start_date) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :start_date, school:, store:, step_params:) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    context 'when the start_date is provided' do
      let(:params) { { start_date: provided_start_date } }

      it 'populate the instance from it' do
        expect(subject.start_date).to eq(provided_start_date)
      end
    end

    context 'when no start_date is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.start_date).to eq(prepopulated_start_date)
      end
    end
  end

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
      let(:start_date) { { 1 => "2024", 2 => "07", 3 => "01" } }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#next_step' do
    it 'returns the next step' do
      expect(subject.next_step).to eq(:working_pattern)
    end
  end

  describe '#previous_step' do
    it 'returns the previous step' do
      expect(subject.previous_step).to eq(:email_address)
    end
  end

  context '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "start_date" => { "start_date(1i)" => "2024", "start_date(2i)" => "07", "start_date(3i)" => "01" }
      )
    end

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :start_date)
      end
    end

    context 'when the step is valid' do
      it 'updates the wizard ect start date' do
        expect { subject.save! }
          .to change(subject.ect, :start_date).to('1 July 2024')
      end
    end
  end
end
