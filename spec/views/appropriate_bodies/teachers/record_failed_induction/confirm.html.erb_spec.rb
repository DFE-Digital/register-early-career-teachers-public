RSpec.describe "appropriate_bodies/teachers/record_failed_induction/confirm.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  let(:author) do
    FactoryBot.create(:appropriate_body_user,
                      dfe_sign_in_organisation_id: appropriate_body_period.dfe_sign_in_organisation_id)
  end

  let(:record_fail) do
    AppropriateBodies::RecordFail.new(teacher:, appropriate_body_period:, author:)
  end

  before do
    FactoryBot.create(:induction_period, :ongoing,
                      appropriate_body_period:,
                      teacher:)

    assign(:appropriate_body_period, appropriate_body_period)
    assign(:teacher, teacher)
    assign(:record_fail, record_fail)

    render
  end

  it "renders a form with the expected fields" do
    expect(rendered).to have_css("form")
  end

  it "links to appeal documentation" do
    expect(rendered).to have_link("about the appeal process (opens in new tab)", href: "https://www.gov.uk/guidance/newly-qualified-teacher-nqt-induction-appeals")
  end
end
