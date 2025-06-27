RSpec.describe "Completed parity checks" do
  include ActionView::Helpers::DateHelper

  before do
    FactoryBot.create(:lead_provider)
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  scenario "Viewing completed parity checks" do
    completed_run = FactoryBot.create(:parity_check_run, :completed)

    statements_endpoint = FactoryBot.create(:parity_check_endpoint, path: "/api/v1/statements")
    user_endpoint = FactoryBot.create(:parity_check_endpoint, path: "/api/v1/users/:id")

    FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching different], run: completed_run, endpoint: statements_endpoint)
    FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching matching], run: completed_run, endpoint: user_endpoint)

    page.goto(new_migration_parity_check_path)
    page.get_by_role("link", name: "View completed runs").click

    expect(page.get_by_role("heading", name: "Completed parity checks")).to be_visible

    expect(page.get_by_text(/In concurrent mode/)).not_to be_visible
    page.get_by_text("How the run mode affects performance").click
    expect(page.get_by_text(/In concurrent mode/)).to be_visible

    completed_run_details = page.locator("table tbody")
    expect(completed_run_details.get_by_text(completed_run.id.to_s)).to be_visible
    expect(completed_run_details.get_by_text("Statements")).to be_visible
    expect(completed_run_details.get_by_text("Users")).to be_visible
    expect(completed_run_details.get_by_text("3 minutes")).to be_visible
    expect(completed_run_details.get_by_text("Concurrent")).to be_visible
    expect(completed_run_details.get_by_text("50%")).to be_visible
    expect(completed_run_details.get_by_text(/faster|slower|equal/)).to be_visible

    expect(page.locator(".govuk-pagination")).not_to be_visible
  end

  scenario "Paginating the completed parity checks when there are many" do
    FactoryBot.create_list(:parity_check_run, Pagy::DEFAULT[:limit] + 1, :completed)

    page.goto(completed_migration_parity_checks_path)

    expect(page.locator("tbody tr")).to have_count(Pagy::DEFAULT[:limit])

    pagination = page.locator(".govuk-pagination")
    expect(pagination).to be_visible

    expect(pagination.get_by_role("link", name: "1")).to be_visible
    expect(pagination.get_by_role("link", name: "2")).to be_visible

    pagination.get_by_role("link", name: "Next").click
    expect(page.locator("tbody tr")).to have_count(1)
  end

  scenario "Viewing completed parity checks when there are none" do
    page.goto(new_migration_parity_check_path)

    expect(page.get_by_role("link", name: "View completed runs")).not_to be_visible

    page.goto(completed_migration_parity_checks_path)

    expect(page.get_by_role("heading", name: "Completed parity checks")).to be_visible
    expect(page.get_by_text("There are no completed parity checks.")).to be_visible

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Run a parity check").click
    expect(page.url).to end_with(new_migration_parity_check_path)
  end
end
