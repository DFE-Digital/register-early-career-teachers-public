RSpec.describe NumberHelper, type: :helper do
  describe "#number_to_pounds" do
    context "when positive number" do
      it "returns pounds" do
        expect(helper.number_to_pounds(BigDecimal("100.0"))).to eql("£100.00")
      end
    end

    context "when negative number" do
      it "returns pounds" do
        expect(helper.number_to_pounds(BigDecimal("-100.0"))).to eql("-£100.00")
      end
    end

    context "when negative zero" do
      it "returns unsigned zero" do
        expect(helper.number_to_pounds(BigDecimal("-0"))).to eql("£0.00")
      end
    end
  end
end
