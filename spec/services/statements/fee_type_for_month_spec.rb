describe Statements::FeeTypeForMonth do
  it "identifies the correct fee type for a given month" do
    expect(described_class.new(month: 1).call).to eq("output")   # January
    expect(described_class.new(month: 2).call).to eq("service")  # February
    expect(described_class.new(month: 3).call).to eq("service")  # March
    expect(described_class.new(month: 4).call).to eq("output")   # April
    expect(described_class.new(month: 5).call).to eq("service")  # May
    expect(described_class.new(month: 6).call).to eq("service")  # June
    expect(described_class.new(month: 7).call).to eq("service")  # July
    expect(described_class.new(month: 8).call).to eq("output")   # August
    expect(described_class.new(month: 9).call).to eq("service")  # September
    expect(described_class.new(month: 10).call).to eq("service") # October
    expect(described_class.new(month: 11).call).to eq("output")  # November
    expect(described_class.new(month: 12).call).to eq("service") # December
    expect(described_class.new(month: nil).call).to be_nil
  end
end
