describe Schools::RegisterECTWizard::ReviewECTDetailsStep, type: :model do
  describe 'validations' do
    subject { described_class.new(change_name:, corrected_name:) }

    context 'when change_name is "yes" and a corrected_name is present' do
      let(:change_name) { "yes" }
      let(:corrected_name) { "John Doe" }

      it 'is valid with a corrected_name' do
        expect(subject).to be_valid
      end
    end

    context 'when change_name is "yes" and a corrected_name is not present' do
      let(:change_name) { "yes" }
      let(:corrected_name) { nil }

      it 'is not valid without a corrected_name' do
        expect(subject).not_to be_valid
        expect(subject.errors[:corrected_name]).to include("Enter the correct full name")
      end
    end

    context 'when change_name is "no"' do
      let(:change_name) { "no" }
      let(:corrected_name) { nil }

      it 'is valid without a corrected_name' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#next_step' do
    subject { described_class.new }

    it 'returns :check_answers' do
      expect(subject.next_step).to eq(:email_address)
    end
  end

  describe '#previous_step' do
    subject { described_class.new }

    it 'returns :find_ect' do
      expect(subject.previous_step).to eq(:find_ect)
    end
  end

  context '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "review_ect_details" => {
          "change_name" => 'yes',
          "corrected_name" => "John Smith",
        }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :review_ect_details, step_params:) }

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :corrected_name)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect corrected name' do
        expect { subject.save! }
          .to change(subject.ect, :corrected_name).from(nil).to('John Smith')
      end
    end
  end
end
