RSpec.describe "View parity check response" do
  include ActionView::Helpers::NumberHelper

  before do
    sign_in_as_dfe_user(role: :admin)
    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  scenario "Viewing a parity check response" do
    run = FactoryBot.create(:parity_check_run, :completed)
    response = FactoryBot.create(:parity_check_response, :different)
    request = FactoryBot.create(:parity_check_request, :completed, run:, responses: [response])

    page.goto(migration_parity_check_request_path(run, request))
    page.get_by_role("link", name: "Response details").click

    expect(page.locator(".govuk-caption-m").get_by_text(request.description)).to be_visible
    expect(page.get_by_role("heading", name: response.description)).to be_visible

    expect(page.get_by_text("The status code from ECF was 200 and the response took #{number_with_delimiter(response.ecf_time_ms)}ms.")).to be_visible
    expect(page.get_by_text("The status code from RECT was 201 and the response took #{number_with_delimiter(response.rect_time_ms)}ms.")).to be_visible
    expect(page.get_by_text("The response bodies were different")).to be_visible
    expect(page.get_by_text(/(equal|faster|slower) performance when compared to ECF/)).to be_visible

    expect(page.get_by_text(/The diff below highlights/)).not_to be_visible
    page.get_by_text("Understanding the differences").click
    expect(page.get_by_text(/The diff below highlights/)).to be_visible

    diff = page.locator(".diff")
    expect(diff.get_by_text(response.ecf_body)).to be_visible
    expect(diff.get_by_text(response.rect_body)).to be_visible

    expect(page.locator(".diff-filter")).not_to be_visible
  end

  scenario "Viewing a parity check response where the bodies are filterable", :js do
    ecf_body = { key: { nested: :value, additional_nested: :nested_data } }.to_json
    rect_body = { key: { nested: :different_value }, additional: :data }.to_json
    response = FactoryBot.create(:parity_check_response, ecf_body:, rect_body:)

    page.goto(migration_parity_check_response_path(response.run, response))

    diff = page.locator(".diff")
    expect(diff.locator(".del").get_by_text(%("nested": "value"))).to be_visible
    expect(diff.locator(".ins").get_by_text(%("nested": "different_value"))).to be_visible
    expect(diff.locator(".ins").get_by_text(%("additional": "data"))).to be_visible

    filter = page.locator(".diff-filter")
    expect(filter).to be_visible

    filter.locator("input[type='checkbox'][value='key']").uncheck
    expect(filter.locator("input[type='checkbox'][value='key nested']")).not_to be_checked
    expect(filter.locator("input[type='checkbox'][value='key additional_nested']")).not_to be_checked
    expect(filter.locator("input[type='checkbox'][value='additional']")).to be_checked

    expect(diff.get_by_text(%("nested": "value"))).not_to be_visible
    expect(diff.get_by_text(%("nested": "different_value"))).not_to be_visible
    expect(diff.locator(".ins").get_by_text(%("additional": "data"))).to be_visible

    filter.locator("input[type='checkbox'][value='additional']").uncheck

    expect(page.get_by_text("No differences found 🙌")).to be_visible

    filter.locator("input[type='checkbox'][value='key nested']").check
    expect(filter.locator("input[type='checkbox'][value='key']")).to be_checked
    expect(filter.locator("input[type='checkbox'][value='key additional_nested']")).not_to be_checked
    expect(filter.locator("input[type='checkbox'][value='additional']")).not_to be_checked
  end

  scenario "Viewing a parity check response where the bodies match" do
    response = FactoryBot.create(:parity_check_response, :different_status_code_matching_body)

    page.goto(migration_parity_check_response_path(response.run, response))

    expect(page.get_by_text("The response bodies were the same")).to be_visible

    expect(page.get_by_text("Understanding the differences")).not_to be_visible
    expect(page.get_by_text(response.ecf_body)).not_to be_visible
    expect(page.get_by_text(response.rect_body)).not_to be_visible
  end

  scenario "Navigating back to the parity check request" do
    response = FactoryBot.create(:parity_check_response, :different)

    page.goto(migration_parity_check_response_path(response.run, response))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: response.request.description).click
    expect(page.url).to end_with(migration_parity_check_request_path(response.run, response.request))
  end

  scenario "Navigating back to the parity check run" do
    response = FactoryBot.create(:parity_check_response, :different)

    page.goto(migration_parity_check_response_path(response.run, response))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Parity check run ##{response.run.id}").click
    expect(page.url).to end_with(migration_parity_check_path(response.run))
  end

  scenario "Navigating back to completed parity checks" do
    response = FactoryBot.create(:parity_check_response, :different)

    page.goto(migration_parity_check_response_path(response.run, response))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Completed parity checks").click
    expect(page.url).to end_with(completed_migration_parity_checks_path)
  end

  scenario "Navigating back to run a parity check" do
    response = FactoryBot.create(:parity_check_response, :different)

    page.goto(migration_parity_check_response_path(response.run, response))

    breadcrumbs = page.locator(".govuk-breadcrumbs")
    breadcrumbs.get_by_role("link", name: "Run a parity check").click
    expect(page.url).to end_with(new_migration_parity_check_path)
  end
end
