RSpec.describe CSVSupport::RowSanitizer do
  describe ".sanitize" do
    subject(:sanitize) { described_class.sanitize(row) }

    let(:row) { ["normal", "=danger", "+sum", "-something", "@handle", "  =spaced", true, 123, nil] }

    it "prefixes string values starting with spreadsheet formula characters" do
      expect(sanitize).to eq([
        "normal",
        "'=danger",
        "'+sum",
        "'-something",
        "'@handle",
        "'  =spaced",
        true,
        123,
        nil
      ])
    end

    it "does not mutate the original row" do
      original = row.dup

      sanitize

      expect(row).to eq(original)
    end
  end
end
