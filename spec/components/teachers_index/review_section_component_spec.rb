RSpec.describe TeachersIndex::ReviewSectionComponent, type: :component do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:component) { described_class.new(appropriate_body:) }
  let(:number_of_ect_records_to_review) { 0 }

  before do
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

    it "displays a count of 0" do
      expect(page).to have_css("h3", text: "0")
    end
  end

  context "when there is one ECT record to review" do
    let(:number_of_ect_records_to_review) { 1 }

    it "displays the number of ECT records to review" do
      expect(page).to have_css("h3", text: "1")
    end

    it "displays singular card label text" do
      expect(page).to have_text("ECT induction record to review")
    end
  end

  context "when there are multiple ECT records to review" do
    let(:number_of_ect_records_to_review) { 3 }

    it "displays the number of ECT records to review" do
      expect(page).to have_css("h3", text: "3")
    end
  end

  it "displays the card label text" do
    expect(page).to have_text("ECT induction records to review")
  end
end
