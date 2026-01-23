RSpec.describe "Submitting a support query", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }

  scenario "happy path" do
    sign_in_as_school_user(school:, first_name: "Jane", last_name: "Smith", email: "jane.smith@example.com")

    page.get_by_role("link", name: "Contact support").click
    page.get_by_label("Your message").fill("I need help registering a new ECT")

    expect { page.get_by_role("button", name: "Send").click }.to change(SupportQuery, :count).by(1)

    support_query = SupportQuery.last
    expect(support_query).to have_attributes(
      name: "Jane Smith",
      email: "jane.smith@example.com",
      school_name: school.name,
      school_urn: school.urn,
      message: "I need help registering a new ECT"
    )
    expect(SupportQuery::SendToZendeskJob).to have_been_enqueued.with(support_query)
  end
end
