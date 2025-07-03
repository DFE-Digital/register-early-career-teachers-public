RSpec.describe "Run parity check" do
  let(:ecf_url) { "https://ecf.example.com" }
  let(:rect_url) { "https://rect.example.com" }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:get_endpoint) { FactoryBot.create(:parity_check_endpoint, :get, path: "/api/v1/statements") }
  let!(:post_endpoint) { FactoryBot.create(:parity_check_endpoint, :post, path: "/api/v1/statement") }
  let!(:put_endpoint) { FactoryBot.create(:parity_check_endpoint, :put, path: "/api/v3/users") }

  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({
      enabled: true,
      ecf_url:,
      rect_url:,
      tokens: { lead_provider.ecf_id => "test-token" }
    })
  end

  scenario "Running a parity check with endpoints selected" do
    page.goto(new_migration_parity_check_path)

    expect(page.get_by_role("heading", name: "Run a parity check")).to be_visible
    expect(page.get_by_text("Select endpoints you would like to run a parity check against.")).to be_visible

    expect(page.locator("legend").and(page.get_by_text("Statements"))).to be_visible
    expect(page.get_by_label(get_endpoint.description)).to be_visible
    page.get_by_label(post_endpoint.description).click

    expect(page.locator("legend").and(page.get_by_text("Users"))).to be_visible
    page.get_by_label(put_endpoint.description).click

    page.get_by_text("Sequential").click

    page.get_by_role("button", name: "Run").click

    expect(page.get_by_text("Parity check run has been created")).to be_visible

    created_run = ParityCheck::Run.last
    expect(created_run).to be_in_progress
    expect(created_run.mode).to eq("sequential")

    expect(page.get_by_text("In-progress run")).to be_visible
    expect(page.get_by_text("Run ##{created_run.id}")).to be_visible
    expect(page.get_by_text("0%")).to be_visible
    expect(page.locator('progress[value="0"]')).to be_visible

    perform_next_parity_check_request_job(ecf_url:, rect_url:)

    page.reload
    expect(page.get_by_text("50%")).to be_visible
    expect(page.locator('progress[value="50"]')).to be_visible

    perform_next_parity_check_request_job(ecf_url:, rect_url:)

    page.reload
    expect(page.get_by_text("In-progress run")).not_to be_visible

    expect(created_run.reload).to be_completed
  end

  scenario "Running a parity check with no endpoints selected" do
    page.goto(new_migration_parity_check_path)

    page.get_by_role("button", name: "Run").click

    expect(page.get_by_role("heading", name: "There is a problem")).to be_visible
    expect(page.locator(".govuk-error-summary a").and(page.get_by_text("Select at least one endpoint."))).to be_visible
  end

  scenario "Running a parity check when there are no lead providers" do
    LeadProvider.destroy_all

    page.goto(new_migration_parity_check_path)

    page.get_by_label(post_endpoint.description).click

    page.get_by_role("button", name: "Run").click
    page.screenshot(path: "tmp.png")

    expect(page.get_by_role("heading", name: "There is a problem")).to be_visible
    expect(page.locator(".govuk-error-summary a").and(page.get_by_text("There are no lead providers available; create at least one lead provider to run a parity check."))).to be_visible
  end

  scenario "Running a parity check when there are no endpoints" do
    ParityCheck::Endpoint.destroy_all

    page.goto(new_migration_parity_check_path)

    expect(page.get_by_text("No endpoints available for parity checks.")).to be_visible
    expect(page.get_by_role("form")).not_to be_visible
  end
end
