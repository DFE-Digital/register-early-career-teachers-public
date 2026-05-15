describe Schools::RegistrationWindow do
  let(:first_day_of_closure) { Date.new(2026, 6, 1) }
  let(:last_day_of_closure) { Date.new(2026, 6, 14) }

  describe ".closed?" do
    subject { described_class.closed? }

    before { travel_to date }

    context "on the day before the closed period" do
      let(:date) { first_day_of_closure - 1.day }

      it { is_expected.to be false }
    end

    context "on the first day of the closed period" do
      let(:date) { first_day_of_closure }

      it { is_expected.to be true }
    end

    context "on the day after the closed period begins" do
      let(:date) { first_day_of_closure + 1.day }

      it { is_expected.to be true }
    end

    context "on the last day of the closed period" do
      let(:date) { last_day_of_closure }

      it { is_expected.to be true }
    end

    context "on the day after the closed period" do
      let(:date) { last_day_of_closure + 1.day }

      it { is_expected.to be false }
    end

    context "in a different year" do
      let(:date) { first_day_of_closure + 1.year }

      it { is_expected.to be false }
    end
  end

  describe ".reopens_on" do
    subject { described_class.reopens_on }

    it { is_expected.to eq last_day_of_closure + 1.day }
  end
end
