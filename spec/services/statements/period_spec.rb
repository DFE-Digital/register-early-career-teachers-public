RSpec.describe Statements::Period do
  describe ".for" do
    it "returns a period for the given statement" do
      date = Date.new(2024, 12, 25)
      statement = FactoryBot.build_stubbed(
        :statement,
        month: date.month,
        year: date.year
      )

      period = Statements::Period.for(statement)

      expect(period).to eq "December 2024"
    end
  end

  describe ".from_year_and_month" do
    it "returns a period for the given year and month" do
      year = 2024
      month = 12

      period = Statements::Period.from_year_and_month(year, month)

      expect(period).to eq "December 2024"
    end
  end
end
