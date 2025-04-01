describe ApplicationWizard do
  let(:current_step) { :first_step }
  let(:wizard) { described_class.new(store: {}, current_step:) }

  describe '#allowed_steps' do
    subject { wizard.allowed_steps }

    it "raises an error" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end

  describe '#allowed_step?' do
    subject { wizard.allowed_step? }

    before { allow(wizard).to receive(:allowed_steps).and_return(%i[first_step]) }

    context 'when the current step is included in the list of allowed steps' do
      let(:current_step) { :first_step }

      it { is_expected.to be_truthy }
    end

    context 'when the current step is not included in the list of allowed steps' do
      let(:current_step) { :last_step }

      it { is_expected.to be_falsey }
    end
  end
end
