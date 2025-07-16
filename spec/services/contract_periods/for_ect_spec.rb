describe ContractPeriods::ForECT do
  subject { described_class.new(started_on:, created_at:) }

  let!(:contract_2024) do
    FactoryBot.create(
      :contract_period,
      started_on: Date.new(2024, 9, 1),
      finished_on: Date.new(2025, 8, 31)
    )
  end

  let!(:contract_2025) do
    FactoryBot.create(
      :contract_period,
      started_on: Date.new(2025, 9, 1),
      finished_on: Date.new(2026, 8, 31)
    )
  end

  describe '#call' do
    context 'when started_on falls within a contract period' do
      let(:started_on) { Date.new(2024, 9, 5) }
      let(:created_at) { Date.new(2025, 1, 10) }

      it 'returns the contract period covering the start date' do
        expect(subject.call).to eq(contract_2024)
      end
    end

    context 'when started_on does not match but created_at does' do
      let(:started_on) { Date.new(2023, 8, 1) }
      let(:created_at) { Date.new(2025, 9, 5) }

      it 'returns the contract period covering the created_at date' do
        expect(subject.call).to eq(contract_2025)
      end
    end

    context 'when both started_on and created_at fall within the same period' do
      let(:started_on) { Date.new(2025, 9, 2) }
      let(:created_at) { Date.new(2025, 9, 3) }

      it 'returns the matching contract period' do
        expect(subject.call).to eq(contract_2025)
      end
    end

    context 'when neither date falls within any contract period' do
      let(:started_on) { Date.new(2023, 1, 1) }
      let(:created_at) { Date.new(2023, 2, 1) }

      it 'returns nil' do
        expect(subject.call).to be_nil
      end
    end

    context 'when started_on is exactly the start date of a contract period' do
      let(:started_on) { Date.new(2025, 9, 1) }
      let(:created_at) { Date.new(2024, 9, 1) }

      it 'returns the matching contract period' do
        expect(subject.call).to eq(contract_2025)
      end
    end

    context 'when started_on is exactly the end date of a contract period' do
      let(:started_on) { Date.new(2025, 8, 31) }
      let(:created_at) { Date.new(2024, 9, 1) }

      it 'returns the matching contract period' do
        expect(subject.call).to eq(contract_2024)
      end
    end

    context 'when started_on and created_at are in a future contract period' do
      let(:started_on) { Date.new(2026, 9, 1) }
      let(:created_at) { Date.new(2026, 9, 2) }

      it 'returns nil because the period does not exist yet' do
        expect(subject.call).to be_nil
      end
    end
  end
end
