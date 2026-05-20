RSpec.describe Term do
  describe ".containing" do
    context "when the date falls in the middle of a term" do
      it "returns the surrounding term" do
        term = Term.containing(Date.new(2026, 8, 15))

        expect(term.first_day..term.last_day).to cover(Date.new(2026, 8, 15))
      end
    end

    context "when the date is the first day of a term" do
      it "returns that term" do
        term = Term.containing(Date.new(2026, 6, 1))

        expect(term.first_day).to eq(Date.new(2026, 6, 1))
      end
    end

    context "when the date is the last day of a term" do
      it "returns that term" do
        term = Term.containing(Date.new(2026, 5, 31))

        expect(term.last_day).to eq(Date.new(2026, 5, 31))
      end
    end
  end

  describe ".current" do
    it "covers today" do
      today = Date.new(2026, 5, 19)

      travel_to(today) do
        expect(Term.current.cover?(today)).to be true
      end
    end
  end

  describe "#cover?" do
    let(:term) { Term.new(Date.new(2026, 1, 1), Date.new(2026, 3, 31)) }

    it("is true on the first day")      { expect(term.cover?(Date.new(2026, 1, 1))).to be true }
    it("is true on the last day")       { expect(term.cover?(Date.new(2026, 3, 31))).to be true }
    it("is false before the first day") { expect(term.cover?(Date.new(2025, 12, 31))).to be false }
    it("is false after the last day")   { expect(term.cover?(Date.new(2026, 4, 1))).to be false }
  end
end
