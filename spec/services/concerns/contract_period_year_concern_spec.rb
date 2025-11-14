RSpec.describe ContractPeriodYearConcern do
  let(:host) do
    Class.new {
      include ContractPeriodYearConcern
      public :to_year
    }.new
  end

  it { expect(host.to_year(2025)).to eq 2025 }
  it { expect(host.to_year("2025")).to eq 2025 }
  it { expect(host.to_year(Date.new(2025, 9, 1))).to eq 2025 }
end
