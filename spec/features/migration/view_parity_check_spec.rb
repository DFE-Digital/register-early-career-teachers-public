RSpec.describe "View parity check" do
  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  scenario "Viewing a parity check" do
    run = FactoryBot.create(:parity_check_run, :completed, request_states: %i[completed_different completed_matching])

    page.goto(completed_migration_parity_checks_path)
    page.get_by_role("link", name: "Run details").click

    expect(page.get_by_role("heading", name: "Parity check run ##{run.id}")).to be_visible

    expect(page.get_by_text("Run ##{run.id} was a concurrent run")).to be_visible
    expect(page.get_by_text("started less than a minute ago and took 3 minutes to complete")).to be_visible
    expect(page.get_by_text("Overall the run was 50% successful")).to be_visible
    expect(page.get_by_text(/(equal|faster|slower) performance when compared to ECF/)).to be_visible
    expect(page.get_by_text("The run exercised the miscellaneous endpoint group")).to be_visible

    expect(page.locator("table").count).to eq(2)

    run.lead_providers.each.with_index do |lead_provider, index|
      requests = run.requests.with_lead_provider(lead_provider)

      table = page.locator("table").nth(index)
      expect(table.get_by_text(lead_provider.name)).to be_visible

      requests.each do |request|
        expect(table.get_by_text(request.description)).to be_visible
        expect(table.get_by_text("#{request.match_rate}%")).to be_visible
        expect(table.get_by_text(/faster|slower|equal/)).to be_visible
        expect(table.get_by_role("link", name: "Request details")).to be_visible
      end
    end
  end

  scenario "Navigating back to completed parity checks" do
    run = FactoryBot.create(:parity_check_run, :completed)

    page.goto(migration_parity_check_path(run))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Completed parity checks").click
    expect(page.url).to end_with(completed_migration_parity_checks_path)
  end

  scenario "Navigating back to run a parity check" do
    run = FactoryBot.create(:parity_check_run, :completed)

    page.goto(migration_parity_check_path(run))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Run a parity check").click
    expect(page.url).to end_with(new_migration_parity_check_path)
  end

  scenario "Viewing a parity check with no requests" do
    run = FactoryBot.create(:parity_check_run, :completed)

    page.goto(migration_parity_check_path(run))

    expect(page.get_by_role("heading", name: "Parity check run ##{run.id}")).to be_visible
    expect(page.get_by_text("There were no requests for this parity check.")).to be_visible
  end
end
