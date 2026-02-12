RSpec.describe UnclaimedIndex::DetailedReviewSectionComponent, type: :component do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body) }
  let(:component) { described_class.new(appropriate_body_period:) }

  before do
    allow(component).to receive_messages(
      number_of_claimable_ect_records: 5,
      number_of_missing_qts_records: 3,
      number_of_records_claimed_by_another_appropriate_body: 2
    )
    render_inline(component)
  end

  it "displays the claim section heading" do
    expect(page).to have_css("h2", text: "Check records and claim an ECT")
  end

  it "displays the action required section heading" do
    expect(page).to have_css("h2", text: "ECT records that may need action")
  end

  it "displays the number of claimable ECT records" do
    expect(page).to have_css("h3", text: "5")
    expect(page).to have_css(".govuk-body", text: "Check and claim ECT")
  end

  it "displays the number of missing QTS records" do
    expect(page).to have_css("h3", text: "3")
    expect(page).to have_css(".govuk-body", text: "No QTS")
  end

  it "displays the number of records claimed by another appropriate body" do
    expect(page).to have_css("h3", text: "2")
    expect(page).to have_css(".govuk-body", text: "Currently claimed by another AB")
  end
end
