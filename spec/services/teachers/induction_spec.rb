RSpec.describe Teachers::Induction do
  subject(:service) { described_class.new(teacher) }

  let(:teacher) { FactoryBot.create(:teacher) }

  let(:induction_period_unfinished) do
    FactoryBot.create(:induction_period, :active, teacher:, started_on: 6.months.ago)
  end

  let(:induction_period_finished_one_year_ago) do
    FactoryBot.create(:induction_period, teacher:, started_on: 2.years.ago, finished_on: 1.year.ago)
  end

  let(:induction_period_finished_two_years_ago) do
    FactoryBot.create(:induction_period, teacher:, started_on: 3.years.ago, finished_on: 2.years.ago)
  end

  describe "#current_induction_period" do
    context 'with ongoing period' do
      before do
        induction_period_unfinished
        induction_period_finished_one_year_ago
      end

      it "returns the current active induction period" do
        expect(service.current_induction_period).to eq(induction_period_unfinished)
      end
    end

    context 'without ongoing period' do
      before { induction_period_finished_one_year_ago }

      it { expect(service.current_induction_period).to be_nil }
    end
  end

  describe "#past_induction_periods" do
    before do
      induction_period_unfinished
      induction_period_finished_one_year_ago
      induction_period_finished_two_years_ago
    end

    it "returns completed induction periods ordered by finish date descending (most recent completed first)" do
      expect(service.past_induction_periods).to eq([
        induction_period_finished_one_year_ago,
        induction_period_finished_two_years_ago
      ])
    end
  end

  describe "#induction_start_date" do
    context "with induction periods" do
      before do
        induction_period_finished_one_year_ago
        induction_period_finished_two_years_ago
      end

      it "returns the start date of the first induction period" do
        expect(service.induction_start_date).to eq(3.years.ago.to_date)
      end
    end

    context "without induction periods" do
      it { expect(service.induction_start_date).to be_nil }
    end
  end

  describe "#has_induction_periods?" do
    context "when teacher has induction periods" do
      before { induction_period_finished_one_year_ago }

      it { is_expected.to have_induction_periods }
    end

    context "when teacher has no induction periods" do
      it { is_expected.not_to have_induction_periods }
    end
  end

  describe "#has_extensions?" do
    context "with induction extensions" do
      before { FactoryBot.create(:induction_extension, teacher:) }

      it { is_expected.to have_extensions }
    end

    context "without induction extensions" do
      it { is_expected.not_to have_extensions }
    end
  end

  describe "#with_appropriate_body?" do
    let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:) }

    it "returns true when the current induction is with the body" do
      expect(service.with_appropriate_body?(induction_period.appropriate_body)).to be true
    end

    it "returns false when the current induction is with another body" do
      expect(service.with_appropriate_body?(other_appropriate_body)).to be false
    end
  end
end
