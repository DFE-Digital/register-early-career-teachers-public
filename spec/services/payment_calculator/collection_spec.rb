describe PaymentCalculator::Collection do
  let(:collection) { described_class.new(calculators) }
  let(:calculators) { [flat_rate, banded] }
  let(:banded) { double("banded calculator", banded?: true, flat_rate?: false) }
  let(:flat_rate) { double("flat-rate calculator", banded?: false, flat_rate?: true) }

  describe "ordering" do
    it "yields the banded calculator before the flat-rate calculator" do
      expect(collection.to_a).to eq([banded, flat_rate])
    end

    it "is enumerable in that order" do
      expect(collection.map(&:banded?)).to eq([true, false])
    end
  end

  describe "#banded_calculator" do
    subject { collection.banded_calculator }

    it { is_expected.to eq banded }

    context "when there is no banded calculator" do
      let(:calculators) { [flat_rate] }

      it "raises a MissingCalculatorError" do
        expect { subject }.to raise_error(described_class::MissingCalculatorError, /banded/)
      end
    end
  end

  describe "#flat_rate_calculator" do
    subject { collection.flat_rate_calculator }

    it { is_expected.to be flat_rate }

    context "when there is no flat rate calculator" do
      let(:calculators) { [banded] }

      it "raises a MissingCalculatorError" do
        expect { subject }.to raise_error(described_class::MissingCalculatorError, /flat-rate/)
      end
    end
  end
end
