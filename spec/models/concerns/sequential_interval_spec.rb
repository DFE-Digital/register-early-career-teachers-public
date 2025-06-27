describe SequentialInterval do
  describe '.current_on' do
    let!(:reg_period_2024) do
      FactoryBot.create(
        :registration_period,
        year: 2024,
        started_on: Date.new(2024, 9, 1),
        finished_on: Date.new(2025, 8, 31)
      )
    end

    context 'when the given date is within the bounds of a period' do
      it 'finds the period current on the date' do
        date = reg_period_2024.started_on + 6.months
        expect(RegistrationPeriod.current_on(date)).to eql(reg_period_2024)
      end
    end

    context 'when the given date is outside the bounds of a period' do
      it 'returns nil' do
        date = reg_period_2024.started_on - 6.months
        expect(RegistrationPeriod.current_on(date)).to be_nil
      end
    end

    context 'when the given date is on the lower bound of the period' do
      it 'finds the period current on the date' do
        date = reg_period_2024.started_on
        expect(RegistrationPeriod.current_on(date)).to eql(reg_period_2024)
      end
    end

    context 'when the given date is on the upper bound of the period' do
      it 'returns nil' do
        date = reg_period_2024.finished_on
        expect(RegistrationPeriod.current_on(date)).to be_nil
      end
    end
  end
end
