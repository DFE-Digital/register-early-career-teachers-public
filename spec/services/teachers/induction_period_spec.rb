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

  context '#ongoing_induction_period' do
    context 'without ongoing induction period' do
      before do
        FactoryBot.create(:induction_period, teacher:, started_on: '2023-10-3', finished_on: '2023-12-3')
      end

      it { expect(service.ongoing_induction_period).to be_nil }
    end

    context "with ongoing induction period" do
      let!(:ongoing_induction_period) do
        FactoryBot.create(:induction_period, :active, teacher:, started_on: '2023-10-3')
      end

      it 'returns the active open induction period' do
        expect(service.ongoing_induction_period).to eq(ongoing_induction_period)
      end
    end
  end
end
