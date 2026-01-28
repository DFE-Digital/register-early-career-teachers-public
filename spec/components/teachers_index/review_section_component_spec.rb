RSpec.describe TeachersIndex::ReviewSectionComponent, type: :component do
  before { render_inline(component) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:component) { described_class.new(appropriate_body:) }

  it "displays the section heading" do
    expect(page).to have_css("h2", text: "Check data from schools")
  end

  it "displays the description text" do
    expect(page).to have_text("When a school tells us you are their AB")
  end

  context "when there are no ECT records to review" do
    it "displays a count of 0" do
      expect(page).to have_css("h3", text: "0")
    end
  end

  context "when there is one ECT record to review" do
    before do
      FactoryBot.create(:pending_induction_submission, appropriate_body:)
      render_inline(component)
    end

    it "displays the number of ECT records to review" do
      expect(page).to have_css("h3", text: "1")
    end

    it "displays singular card label text" do
      expect(page).to have_text("ECT induction record to review")
    end
  end

  context "when there are multiple ECT records to review" do
    before do
      FactoryBot.create_list(:pending_induction_submission, 3, appropriate_body:)
      render_inline(component)
    end

    it "displays the number of ECT records to review" do
      expect(page).to have_css("h3", text: "3")
    end
  end

  it "displays the card label text" do
    expect(page).to have_text("ECT induction records to review")
  end
end
