describe Teachers::InductionPeriod do
  subject(:service) { described_class.new(teacher) }

  let(:teacher) { FactoryBot.create(:teacher) }

  context '#induction_start_date' do
    context 'when teacher does not have induction periods' do
      it { expect(service.induction_start_date).to be_nil }
    end

    context "when the teacher has induction periods" do
      let(:expected_date) { Date.new(2022, 10, 2) }
      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let!(:first_induction_period) do
        FactoryBot.create(:induction_period, appropriate_body:, teacher:, started_on: expected_date, finished_on: Date.new(2023, 10, 2))
      end

      let!(:last_induction_period) do
        FactoryBot.create(:induction_period, appropriate_body:, teacher:, started_on: Date.new(2023, 10, 3))
      end

      it 'returns the start date of the first induction period' do
        expect(service.induction_start_date).to eq(expected_date)
      end
    end
  end

  context '#active_induction_period' do
    before do
      InductionPeriod.new(
        appropriate_body: FactoryBot.create(:appropriate_body),
        teacher:,
        started_on: Date.new(2023, 10, 3),
        finished_on: Date.new(2023, 12, 3)
      )
    end

    context 'when teacher does not have an active induction period' do
      it { expect(service.active_induction_period).to be_nil }
    end

    context "when the teacher has an active induction period" do
      let!(:active_induction_period) do
        FactoryBot.create(
          :induction_period,
          :active,
          appropriate_body: FactoryBot.create(:appropriate_body),
          teacher:,
          started_on: Date.new(2024, 10, 3)
        )
      end

      it 'returns the active induction period for the teacher' do
        expect(service.active_induction_period).to eq(active_induction_period)
      end
    end
  end
end
