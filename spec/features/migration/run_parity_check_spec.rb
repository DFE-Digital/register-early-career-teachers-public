RSpec.describe "Run parity check" do
  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  let!(:get_endpoint) { FactoryBot.create(:parity_check_endpoint, :get, path: "/api/v1/statements") }
  let!(:post_endpoint) { FactoryBot.create(:parity_check_endpoint, :post, path: "/api/v1/statement/:id") }
  let!(:put_endpoint) { FactoryBot.create(:parity_check_endpoint, :put, path: "/api/v3/users/:id") }

  scenario "Running a parity check with endpoints selected" do
    page.goto(new_migration_parity_check_path)

    expect(page.get_by_role("heading", name: "Run a parity check")).to be_visible
    expect(page.get_by_text("Select endpoints you would like to run a parity check against.")).to be_visible

    expect(page.locator("legend").and(page.get_by_text("Statements"))).to be_visible
    expect(page.get_by_label(get_endpoint.description)).to be_visible
    page.get_by_label(post_endpoint.description).click

    expect(page.locator("legend").and(page.get_by_text("Users"))).to be_visible
    page.get_by_label(put_endpoint.description).click

    page.get_by_role("button", name: "Run").click

    expect(page.get_by_text("Parity check has been started.")).to be_visible
  end

  scenario "Running a parity check with no endpoints selected" do
    page.goto(new_migration_parity_check_path)

    page.get_by_role("button", name: "Run").click

    expect(page.get_by_role("heading", name: "There is a problem")).to be_visible
    expect(page.locator(".govuk-error-summary a").and(page.get_by_text("Select at least one endpoint."))).to be_visible
  end

  scenario "Running a parity check when there are no endpoints" do
    ParityCheck::Endpoint.destroy_all

    page.goto(new_migration_parity_check_path)

    expect(page.get_by_text("No endpoints available for parity checks.")).to be_visible
    expect(page.get_by_role("form")).not_to be_visible
  end
end
