RSpec.describe Teachers::NameChange do
  describe "#significant?" do
    def significant?(current_name, new_name)
      described_class.new(current_name, new_name).significant?
    end

    it "is false when only the first name changes (typo or short form)" do
      expect(significant?("Jonathan Smith", "Jon Smith")).to be(false)
    end

    it "is false when only the last name changes (e.g. marriage)" do
      expect(significant?("Jane Smith", "Jane Jones")).to be(false)
    end

    it "is true when both the first and last name change" do
      expect(significant?("John Smith", "Mary Jones")).to be(true)
    end

    it "is false when a middle name is added" do
      expect(significant?("John Smith", "John Paul Smith")).to be(false)
    end

    it "is false when only the last part of a multi-part name changes" do
      expect(significant?("Edwin van der Smoot", "Edwin van der Smoot-Jones")).to be(false)
    end

    it "ignores case" do
      expect(significant?("John Smith", "JOHN SMITH")).to be(false)
    end

    it "ignores accents and punctuation" do
      expect(significant?("Zoe O'Brien", "Zoë OBrien")).to be(false)
    end

    it "ignores surrounding and repeated whitespace" do
      expect(significant?("John Smith", "  John   Smith  ")).to be(false)
    end

    it "treats a completely different single-word name as significant" do
      expect(significant?("Cher", "Madonna")).to be(true)
    end

    it "is false when a single-word name is unchanged" do
      expect(significant?("Cher", "Cher")).to be(false)
    end
  end
end
