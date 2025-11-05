RSpec.describe "appropriate_bodies/teachers/record_released_induction/new.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body) }

  let(:author) do
    FactoryBot.create(:appropriate_body_user,
                      dfe_sign_in_organisation_id: appropriate_body_period.dfe_sign_in_organisation_id)
  end

  let(:record_release) do
    AppropriateBodies::RecordRelease.new(teacher:, appropriate_body_period:, author:)
  end

  before do
    FactoryBot.create(:induction_period, :ongoing,
                      appropriate_body_period:,
                      teacher:)

    assign(:appropriate_body, appropriate_body_period)
    assign(:teacher, teacher)
    assign(:record_release, record_release)

    render
  end

  it "renders a form with the expected fields" do
    expect(rendered).to have_css("form")
  end

  it "has a date field for the leaving date" do
    expect(rendered).to have_css("legend", text: "When did their induction end with #{appropriate_body_period.name}?")
    expect(rendered).to have_css("form label", text: "Day")
    expect(rendered).to have_css("form label", text: "Month")
    expect(rendered).to have_css("form label", text: "Year")
  end

  it "has a date field for the extension length" do
    expect(rendered).to have_css("label", text: "How many terms of induction did they spend with you?")
  end

  it "has a submit button" do
    expect(rendered).to have_css("button.govuk-button")
  end
end
