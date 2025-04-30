RSpec.describe Schools::RegisterECTWizard::EmailAddressStep, type: :model do
  subject { described_class.new(wizard:) }

  let(:store) { FactoryBot.build(:session_repository, email: 'prepopulated@example.com') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :email_address, store:) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    context 'when the email is provided' do
      let(:provided_email) { 'provided@example.com' }
      let(:params) { { email: provided_email } }

      it 'populate the instance from it' do
        expect(subject.email).to eq(provided_email)
      end
    end

    context 'when no email is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.email).to eq('prepopulated@example.com')
      end
    end
  end

  describe 'validations' do
    subject { described_class.new(email:) }

    context 'when email is not present' do
      let(:email) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("Enter the email address")
      end
    end

    context 'when email not in a valid format' do
      let(:email) { 'invalid_email' }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("Enter an email address in the correct format, like name@example.com")
      end
    end

    context 'when email is in a valid format' do
      let(:email) { 'foo@bar.com' }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#next_step' do
    it 'returns the next step' do
      expect(subject.next_step).to eq(:start_date)
    end
  end

  describe '#previous_step' do
    it 'returns the previous step' do
      expect(subject.previous_step).to eq(:previous_ect_details)
    end
  end

  context '#save!' do
    subject { wizard.current_step }

    let(:step_params) do
      ActionController::Parameters.new(
        "email_address" => {
          "email" => 'foo@bar.com',
        }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :email_address, step_params:) }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :email)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect corrected name' do
        expect { subject.save! }
          .to change(subject.ect, :email).from(nil).to('foo@bar.com')
      end
    end
  end
end
