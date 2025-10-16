describe TestGuidanceComponent, type: :component do
  context "when disabled" do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(false)
    end

    it "does not render content" do
      render_inline(described_class.new) { "some content" }
      expect(rendered_content).to be_blank
    end
  end

  context "when enabled" do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(true)
    end

    it "renders content" do
      render_inline(described_class.new) { "some content" }
      expect(rendered_content).to include("some content")
    end

    describe "TRS example details" do
      it "contains a table with TRNs and dates of birth" do
        render_inline(described_class.new, &:with_trs_example_teacher_details)
        expect(rendered_content).to include("To successfully locate an ECT from the TRS API")
      end
    end

    describe "fake TRS API example details" do
      it "contains a table with TRNs and dates of birth" do
        render_inline(described_class.new, &:with_trs_fake_api_instructions)
        expect(rendered_content).to include("Enter any TRN with the date of birth 03-02-1977 to register a random ECT.")
      end
    end
  end
end
