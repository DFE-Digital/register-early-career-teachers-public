describe ContractPeriods::ForECT do
  subject { described_class.new(started_on:) }

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

      it 'returns the contract period covering the start date' do
        expect(subject.call).to eq(contract_2024)
      end
    end

    context 'when started_on is exactly the start date of a contract period' do
      let(:started_on) { Date.new(2025, 9, 1) }

      it 'returns the matching contract period' do
        expect(subject.call).to eq(contract_2025)
      end
    end

    context 'when started_on is the last included date of a contract period' do
      let(:started_on) { Date.new(2025, 8, 30) }

      it 'returns the matching contract period' do
        expect(subject.call).to eq(contract_2024)
      end
    end

    context 'when started_on does not fall within any contract period' do
      let(:started_on) { Date.new(2023, 1, 1) }

      it 'raises an error' do
        expect { subject.call }.to raise_error(ContractPeriods::ForECT::NoContractPeriodFoundForStartedOnDate)
      end
    end

    context 'when started_on is in a future period that does not yet exist' do
      let(:started_on) { Date.new(2026, 9, 1) }

      it 'raises an error' do
        expect { subject.call }.to raise_error(ContractPeriods::ForECT::NoContractPeriodFoundForStartedOnDate)
      end
    end
  end
end
