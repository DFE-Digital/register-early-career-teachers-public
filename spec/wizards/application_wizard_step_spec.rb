RSpec.describe ApplicationWizardStep, type: :model do
  let(:permitted_params) { %i[param1 param2] }
  let(:instance) { described_class.new(params) }

  before do
    described_class.class_exec(permitted_params) { |permitted_params| attr_accessor(*permitted_params) }
    allow(described_class).to receive(:permitted_params).and_return(permitted_params)
  end

  describe '#initialize' do
    context 'when permitted params are provided' do
      let(:params) { { param1: 1 } }

      before do
        allow(instance).to receive(:pre_populate_attributes).and_call_original
      end

      it 'does not call pre_populate_attributes' do
        expect(instance).not_to have_received(:pre_populate_attributes)
      end
    end

    context 'when no permitted params are provided' do
      let(:params) { {} }

      before do
        allow_any_instance_of(described_class).to receive(:pre_populate_attributes).and_return(nil)
      end

      it 'calls pre_populate_attributes' do
        expect(instance).to have_received(:pre_populate_attributes)
      end
    end
  end

  describe '#pre_populate_attributes' do
    let(:params) { { param1: 1 } }

    it 'raises NotImplementedError' do
      expect { instance.send(:pre_populate_attributes) }.to raise_error(NotImplementedError)
    end
  end
end
