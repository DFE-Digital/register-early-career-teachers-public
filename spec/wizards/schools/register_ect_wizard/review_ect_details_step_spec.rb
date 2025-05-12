describe Schools::RegisterECTWizard::ReviewECTDetailsStep, type: :model do
  subject { described_class.new(wizard:) }

  let(:change_name) { "yes" }
  let(:corrected_name) { "Jane Smith" }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:store) { FactoryBot.build(:session_repository, change_name:, corrected_name:, trn: teacher.trn) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :review_ect_details, store:) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    context 'when the change_name is provided' do
      let(:change_name) { 'no' }
      let(:params) { { change_name: } }

      it 'populate the instance from it' do
        expect(subject.change_name).to eq(change_name)
        expect(subject.corrected_name).to be_nil
      end
    end

    context 'when no attributes are provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.change_name).to eq('yes')
        expect(subject.corrected_name).to eq('Jane Smith')
      end
    end
  end

  describe 'validations' do
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
    context 'with ECTAtSchoolPeriods' do
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }

      it 'returns the previous ect details page' do
        expect(subject.next_step).to eq(:previous_ect_details)
      end
    end

    context 'with no ECTAtSchoolPeriods' do
      it 'returns the email address page' do
        expect(subject.next_step).to eq(:email_address)
      end
    end
  end

  describe '#previous_step' do
    it 'returns :find_ect' do
      expect(subject.previous_step).to eq(:find_ect)
    end
  end

  context '#save!' do
    subject { wizard.current_step }

    let(:step_params) do
      ActionController::Parameters.new(
        "review_ect_details" => {
          "change_name" => 'yes',
          "corrected_name" => "John Smith",
        }
      )
    end
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :review_ect_details, step_params:) }

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
          .to change(subject.ect, :corrected_name)
                .from(nil).to('John Smith')
                .and change(subject.ect, :change_name)
                       .from(nil).to('yes')
      end
    end
  end
end
