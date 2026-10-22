RSpec.describe CorrectedNameValidator, type: :model do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :corrected_name

      validates :corrected_name, corrected_name: true
    end
  end

  context "when the corrected_name is valid" do
    it "does not add any errors for corrected_name" do
      subject = test_class.new(corrected_name: "Rick Collins")
      subject.valid?
      expect(subject).to have_no_error(:corrected_name)
    end
  end

  context "when the corrected_name is too long" do
    it "adds an error for corrected_name" do
      subject = test_class.new(corrected_name: "a" * 71)
      subject.valid?

      expect(subject).to have_error(:corrected_name, "Corrected name must be 70 characters or less")
    end
  end

  context "when the corrected name is blank" do
    it "adds an error" do
      subject = test_class.new(corrected_name: "   ")
      subject.valid?

      expect(subject).to have_error(:corrected_name, "Enter the correct full name")
    end
  end
end
