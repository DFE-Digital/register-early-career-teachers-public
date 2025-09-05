RSpec.describe "View parity check request" do
  include ActionView::Helpers::NumberHelper

  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  scenario "Viewing a parity check request" do
    run = FactoryBot.create(:parity_check_run, :completed)
    responses = [
      FactoryBot.create(:parity_check_response, :matching, page: 1),
      FactoryBot.create(:parity_check_response, :different, page: 2),
    ]
    request = FactoryBot.create(:parity_check_request, :completed, run:, responses:)

    page.goto(migration_parity_check_path(run))
    page.get_by_role("link", name: "Request details").click

    expect(page.locator(".govuk-caption-m").get_by_text(request.lead_provider.name)).to be_visible
    expect(page.get_by_role("heading", name: request.description)).to be_visible

    expect(page.get_by_text("The request resulted in 2 responses that took 3 minutes to complete.")).to be_visible
    expect(page.get_by_text("Overall the request was 50% successful")).to be_visible
    expect(page.get_by_text(/(equal|faster|slower) performance when compared to ECF/)).to be_visible

    expect(page.get_by_text("The response IDs were the same. In total RECT returned 0 IDs and ECF returned 0 IDs.")).to be_visible

    table = page.locator("table")
    expect(table.get_by_text("Responses")).to be_visible

    responses.each.with_index(1) do |response, row_number|
      row = table.locator("tbody tr:nth-child(#{row_number})")

      expect(row.locator("td:nth-child(1)").get_by_text(response.page.to_s)).to be_visible

      expect(row.locator("td:nth-child(2)").get_by_text(response.rect_status_code.to_s)).to be_visible
      expect(row.locator("td:nth-child(3)").get_by_text(number_with_delimiter(response.rect_time_ms))).to be_visible

      expect(row.locator("td:nth-child(4)").get_by_text(response.ecf_status_code.to_s)).to be_visible
      expect(row.locator("td:nth-child(5)").get_by_text(number_with_delimiter(response.ecf_time_ms))).to be_visible

      expect(row.get_by_text(/faster|slower|equal/)).to be_visible
      expect(row.get_by_text(response.matching? ? "✅" : "❌")).to be_visible

      expect(row.get_by_role("link", name: "Response details").visible?).to eq(response.different?)
    end

    expect(page.locator(".govuk-pagination")).not_to be_visible
  end

  scenario "Viewing a parity check request with different IDs in the responses" do
    run = FactoryBot.create(:parity_check_run, :completed)
    response = FactoryBot.create(:parity_check_response, ecf_body: { data: [{ id: 123 }] }.to_json, rect_body: { data: [{ id: 456 }] }.to_json)
    request = FactoryBot.create(:parity_check_request, :completed, run:, responses: [response])

    page.goto(migration_parity_check_request_path(run, request))

    expect(page.get_by_text("The response IDs were different. In total RECT returned 1 ID and ECF returned 1 ID.")).to be_visible

    expect(page.get_by_role("heading", name: "Response IDs")).to be_visible

    expect(page.get_by_text("There was 1 ID returned by ECF that were not returned by RECT.")).to be_visible
    expect(page.get_by_text("There was 1 ID returned by RECT that were not returned by ECF.")).to be_visible
  end

  scenario "Paginating the parity check responses when there are many" do
    run = FactoryBot.create(:parity_check_run, :completed)
    responses = FactoryBot.create_list(:parity_check_response, Pagy::DEFAULT[:limit] + 1, :matching)
    request = FactoryBot.create(:parity_check_request, :completed, run:, responses:)

    responses.each.with_index { |response, index| response.update(page: index + 1) }

    page.goto(migration_parity_check_request_path(run, request))

    expect(page.locator("tbody tr")).to have_count(Pagy::DEFAULT[:limit])

    page_numbers_in_order = page.locator("table tbody tr td:first-child").all.map(&:text_content).map(&:to_i)
    expect(page_numbers_in_order).to eq(page_numbers_in_order.sort)

    pagination = page.locator(".govuk-pagination")
    expect(pagination).to be_visible

    expect(pagination.get_by_role("link", name: "1")).to be_visible
    expect(pagination.get_by_role("link", name: "2")).to be_visible

    pagination.get_by_role("link", name: "Next").click
    expect(page.locator("tbody tr")).to have_count(1)
  end

  scenario "Navigating back to the parity check run" do
    request = FactoryBot.create(:parity_check_request, :completed)

    page.goto(migration_parity_check_request_path(request.run, request))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Parity check run ##{request.run.id}").click
    expect(page.url).to end_with(migration_parity_check_path(request.run))
  end

  scenario "Navigating back to completed parity checks" do
    request = FactoryBot.create(:parity_check_request, :completed)

    page.goto(migration_parity_check_request_path(request.run, request))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Completed parity checks").click
    expect(page.url).to end_with(completed_migration_parity_checks_path)
  end

  scenario "Navigating back to run a parity check" do
    request = FactoryBot.create(:parity_check_request, :completed)

    page.goto(migration_parity_check_request_path(request.run, request))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Run a parity check").click
    expect(page.url).to end_with(new_migration_parity_check_path)
  end
end
