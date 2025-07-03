RSpec.describe "Admin finance statement filter" do
  before do
    sign_in_as_dfe_user(role: :admin)

    given_statements_exist

    when_i_visit_the_statements_page
    then_i_should_see_all_output_statements_listed
  end

  scenario "Filter by lead provider" do
    when_i_filter_by_lead_provider
    then_i_see_statements_filtered_by_lead_provider
  end

  scenario "Filter by contract_period" do
    when_i_filter_by_contract_period
    then_i_see_statements_filtered_by_contract_period
  end

  scenario "Filter by statement date" do
    when_i_filter_by_statement_date
    then_i_see_statements_filtered_by_statement_date
  end

  scenario "Filter by statement type" do
    when_i_filter_by_statement_type
    then_i_see_statements_filtered_by_statement_type
  end

  def given_statements_exist
    @lead_provider1 = FactoryBot.create(:lead_provider)
    @lead_provider2 = FactoryBot.create(:lead_provider)

    @contract_period1 = FactoryBot.create(:contract_period)
    @contract_period2 = FactoryBot.create(:contract_period)

    @active_lead_provider1 = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider1, contract_period: @contract_period1)
    @active_lead_provider2 = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider1, contract_period: @contract_period2)
    @active_lead_provider3 = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider2, contract_period: @contract_period2)

    @statement1 = FactoryBot.create(:statement, active_lead_provider: @active_lead_provider1, fee_type: 'output', year: 2025, month: 5)
    @statement2 = FactoryBot.create(:statement, active_lead_provider: @active_lead_provider1, fee_type: 'service', year: 2023, month: 5)

    @statement3 = FactoryBot.create(:statement, active_lead_provider: @active_lead_provider2, fee_type: 'output', year: 2022, month: 5)
    @statement4 = FactoryBot.create(:statement, active_lead_provider: @active_lead_provider2, fee_type: 'service', year: 2024, month: 5)

    @statement5 = FactoryBot.create(:statement, active_lead_provider: @active_lead_provider3, fee_type: 'output', year: 2025, month: 8)
    @statement6 = FactoryBot.create(:statement, active_lead_provider: @active_lead_provider3, fee_type: 'service', year: 2026, month: 8)
  end

  def when_i_visit_the_statements_page
    page.goto(admin_finance_statements_path)
  end

  def then_i_should_see_all_output_statements_listed
    expect(table_statement_ids).to eq([
      @statement3.id,
      @statement1.id,
      @statement5.id,
    ])
  end

  def when_i_filter_by_lead_provider
    filter = page.locator(".app-admin-filter")

    elem = filter.get_by_label("Lead provider", exact: true)
    elem.select_option(label: @lead_provider1.name)

    filter.get_by_role('button', name: "View").click
  end

  def then_i_see_statements_filtered_by_lead_provider
    expect(table_statement_ids).to eq([
      @statement3.id,
      @statement1.id,
    ])
  end

  def when_i_filter_by_contract_period
    filter = page.locator(".app-admin-filter")

    elem = filter.get_by_label("Contract year", exact: true)
    elem.select_option(label: @contract_period2.year.to_s)

    filter.get_by_role('button', name: "View").click
  end

  def then_i_see_statements_filtered_by_contract_period
    expect(table_statement_ids).to eq([
      @statement3.id,
      @statement5.id,
    ])
  end

  def when_i_filter_by_statement_date
    filter = page.locator(".app-admin-filter")

    elem = filter.get_by_label("Statement date", exact: true)
    elem.select_option(label: "May 2022")

    filter.get_by_role('button', name: "View").click
  end

  def then_i_see_statements_filtered_by_statement_date
    expect(table_statement_ids).to eq([
      @statement3.id,
    ])
  end

  def when_i_filter_by_statement_type
    filter = page.locator(".app-admin-filter")

    elem = filter.get_by_label("Statement type", exact: true)
    elem.select_option(label: "All")

    filter.get_by_role('button', name: "View").click
  end

  def then_i_see_statements_filtered_by_statement_type
    expect(table_statement_ids).to eq([
      @statement3.id,
      @statement2.id,
      @statement4.id,
      @statement1.id,
      @statement5.id,
      @statement6.id,
    ])
  end

  def table_statement_ids
    page.query_selector_all("table.govuk-table .govuk-table__body .govuk-table__row .govuk-table__cell .govuk-link").map { |v| v.get_attribute("href").split("/").last.to_i }
  end
end
