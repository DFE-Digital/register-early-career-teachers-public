describe API::DateTimeFormatCheck do
  subject(:checker) { described_class.new(date) }

  describe "#valid?" do
    context "when the date is a valid RFC3339 formatted value" do
      let(:date) { Time.zone.now.rfc3339 }

      it { is_expected.to be_valid }
    end

    context "when the date is not in RFC3339 format" do
      let(:date) { "2024-12-01" }

      it { is_expected.to be_invalid }
    end

    context "when the date is blank" do
      let(:date) { "" }

      it { is_expected.to be_invalid }
    end

    context "when the date is nil" do
      let(:date) { nil }

      it { is_expected.to be_invalid }
    end

    context "when the date is random text" do
      let(:date) { "bananas" }

      it { is_expected.to be_invalid }
    end
  end
end
