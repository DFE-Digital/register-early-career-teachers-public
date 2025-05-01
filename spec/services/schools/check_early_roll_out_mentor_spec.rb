RSpec.describe Schools::CheckEarlyRollOutMentor do
  subject(:service) { described_class.new(trn) }

  let(:trn) { '7654321' }

  describe '#early_roll_out_mentor?' do
    context 'with ERO record' do
      before { FactoryBot.create(:early_roll_out_mentor, trn:) }

      it { expect(service).to be_early_roll_out_mentor }
    end

    context 'without ERO record' do
      it { expect(service).not_to be_early_roll_out_mentor }
    end
  end

  describe '#to_h' do
    context 'with ERO record' do
      before { FactoryBot.create(:early_roll_out_mentor, trn:) }

      it 'returns ERO date and reason params' do
        expect(service.to_h).to eq({
          mentor_became_ineligible_for_funding_reason: 'completed_during_early_roll_out',
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19)
        })
      end
    end

    context 'without ERO record' do
      it 'returns empty ERO date and reason params ' do
        expect(service.to_h).to eq({
          mentor_became_ineligible_for_funding_reason: nil,
          mentor_became_ineligible_for_funding_on: nil
        })
      end
    end
  end
end
