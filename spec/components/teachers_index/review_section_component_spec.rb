RSpec.describe TeachersIndex::ReviewSectionComponent, type: :component do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:component) { described_class.new(appropriate_body:) }
  let(:number_of_ect_records_to_review) { 0 }

  context "when disabled" do
    before do
      allow(Rails.application.config).to receive(:enable_appropriate_body_records_to_review).and_return(false)
      render_inline(component)
    end

    it { expect(rendered_content).to be_blank }
  end

  context "when enabled" do
    before do
      allow(Rails.application.config).to receive(:enable_appropriate_body_records_to_review).and_return(true)
      allow(component).to receive(:number_of_ect_records_to_review).and_return(number_of_ect_records_to_review)
      render_inline(component)
    end

    it "displays the section heading" do
      expect(page).to have_css("h2", text: "Check data from schools")
    end

    it "displays the description text" do
      expect(page).to have_text("When a school tells us you are their AB")
    end

    context "when there are no ECT records to review" do
      let(:number_of_ect_records_to_review) { 0 }

      it "displays a message that there are no records to review" do
        expect(page).to have_css(".govuk-inset-text", text: "You have no ECT induction records to review.")
      end
    end

    context "when there is one ECT record to review" do
      let(:number_of_ect_records_to_review) { 1 }

      it "displays a button with singular text" do
        expect(page).to have_link("Review 1 ECT induction record")
      end
    end

    context "when there are multiple ECT records to review" do
      let(:number_of_ect_records_to_review) { 3 }

      it "displays a button with plural text" do
        expect(page).to have_link("Review 3 ECT induction records")
      end
    end
  end
end
