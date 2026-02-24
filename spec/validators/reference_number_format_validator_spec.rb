describe ReferenceNumberFormatValidator do
  let(:validation_options) do
    {
      allow_blank: true,
      maximum: 6,
      minimum: 5,
      message: "URN must be 5 or 6 numbers"
    }
  end
  let(:reference_number) { "123456" }

  let(:model_class) do
    options = validation_options

    Class.new do
      include ActiveModel::Validations

      attr_accessor :reference_number

      validates :reference_number, reference_number_format: options
    end
  end

  let(:model) do
    record = model_class.new
    record.reference_number = reference_number
    record
  end

  describe "reference number validation" do
    context "with a valid reference number" do
      it "does not add an error" do
        expect(model).to be_valid
      end
    end

    context "without a reference number" do
      let(:reference_number) { nil }

      it "does not add an error" do
        expect(model).to be_valid
      end
    end

    context "with a short reference number" do
      let(:reference_number) { "1234" }

      it "adds an error" do
        expect(model).to be_invalid
        expect(model.errors[:reference_number]).to contain_exactly("URN must be 5 or 6 numbers")
      end
    end

    context "with a long reference number" do
      let(:reference_number) { "1234567" }

      it "adds an error" do
        expect(model).to be_invalid
        expect(model.errors[:reference_number]).to contain_exactly("URN must be 5 or 6 numbers")
      end
    end

    context "with a reference number containing letters" do
      let(:reference_number) { "abc123" }

      it "adds an error" do
        expect(model).to be_invalid
        expect(model.errors[:reference_number]).to contain_exactly("URN must be 5 or 6 numbers")
      end
    end
  end

  context "when regex pattern is provided" do
    let(:validation_options) do
      {
        allow_blank: true,
        minimum: 5,
        maximum: 6,
        with: /\A(?:2\d{4}|[14]\d{5})\z/,
        message: "URN must be 5 or 6 numbers"
      }
    end

    context "with a value matching the pattern" do
      let(:reference_number) { "123456" }

      it "is valid" do
        expect(model).to be_valid
      end
    end

    context "with a value not matching the pattern" do
      let(:reference_number) { "212345" }

      it "adds an error" do
        expect(model).to be_invalid
        expect(model.errors[:reference_number]).to contain_exactly("URN must be 5 or 6 numbers")
      end
    end
  end

  context "when message is not provided" do
    let(:validation_options) do
      {
        allow_blank: false,
        minimum: 8,
        maximum: 8
      }
    end
    let(:reference_number) { "1234567" }

    it "uses the default message" do
      expect(model).to be_invalid
      expect(model.errors[:reference_number]).to contain_exactly("is invalid")
    end
  end
end
