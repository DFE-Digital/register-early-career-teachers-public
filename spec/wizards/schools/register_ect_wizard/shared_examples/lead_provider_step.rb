RSpec.shared_examples "a lead provider step" do
  describe 'validations' do
    subject { described_class.new(lead_provider_id:) }

    context 'when the lead_provider_id is not present' do
      let(:lead_provider_id) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:lead_provider_id]).to include("Select which lead provider will be training the ECT")
      end
    end

    context 'when the lead_provider_id is not known' do
      let(:lead_provider_id) { '1' }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:lead_provider_id]).to include("Enter the name of a known lead provider")
      end
    end

    context 'when the lead_provider_id is present and the lead provider exists' do
      let(:lead_provider_id) { lead_provider.id }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }

      it { expect(subject).to be_valid }
    end
  end

  describe 'steps' do
    subject { wizard.current_step }

    let(:wizard) do
      FactoryBot.build(:register_ect_wizard, current_step: :lead_provider)
    end

    describe '#next_step' do
      it 'returns the next step' do
        expect(subject.next_step).to eq(:check_answers)
      end
    end

    describe '#previous_step' do
      it 'returns the previous step' do
        expect(subject.previous_step).to eq(:programme_type)
      end
    end
  end

  describe '#save!' do
    let(:step_params) do
      ActionController::Parameters.new(
        "lead_provider" => {
          "lead_provider_id" => '1',
        }
      )
    end

    let(:wizard) do
      FactoryBot.build(:register_ect_wizard, current_step: :lead_provider, step_params:)
    end

    subject { wizard.current_step }

    context 'when the step is not valid' do
      before do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :lead_provider_id)
      end
    end

    context 'when the step is valid' do
      before do
        allow(subject).to receive(:valid?).and_return(true)
      end

      it 'updates the wizard ect lead_provider_id' do
        expect { subject.save! }.to change(subject.ect, :lead_provider_id).from(nil).to('1')
      end
    end
  end
end
