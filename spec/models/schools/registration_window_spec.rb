describe Schools::RegistrationWindow do
  subject { described_class }

  let(:first_day_of_closure) { Date.new(2026, 6, 1) }
  let(:last_day_of_closure) { Date.new(2026, 6, 14) }

  before do
    allow(Schools::RegistrationWindow).to receive(:closed?).and_call_original
  end

  describe ".closed?" do
    before { travel_to date }

    context "on the day before the closed period" do
      let(:date) { first_day_of_closure - 1.day }

      it { is_expected.not_to be_closed }
    end

    context "on the first day of the closed period" do
      let(:date) { first_day_of_closure }

      it { is_expected.to be_closed }
    end

    context "on the day after the closed period begins" do
      let(:date) { first_day_of_closure + 1.day }

      it { is_expected.to be_closed }
    end

    context "on the last day of the closed period" do
      let(:date) { last_day_of_closure }

      it { is_expected.to be_closed }
    end

    context "on the day after the closed period" do
      let(:date) { last_day_of_closure + 1.day }

      it { is_expected.not_to be_closed }
    end

    context "in a different year" do
      let(:date) { first_day_of_closure + 1.year }

      it { is_expected.not_to be_closed }
    end
  end

  describe ".reopens_on" do
    subject { described_class.reopens_on }

    it { is_expected.to eq last_day_of_closure + 1.day }
  end
end
