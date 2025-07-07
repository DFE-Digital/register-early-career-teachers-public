RSpec.describe "Admin finance statement selector" do
  before do
    sign_in_as_dfe_user(role: :admin)

    given_statement_exist_with_dropdown_options
    when_i_visit_the_statement_page
    then_i_should_see_statement_with_selected_options
  end

  scenario "Select a statement that exists" do
    when_i_select_a_different_statement
    then_i_am_redirected_different_statement
  end

  scenario "Select a statement that does not exist" do
    when_i_select_a_statement_that_does_not_exist
    then_i_am_redirected_to_statement_not_found_page
  end

  def given_statement_exist_with_dropdown_options
    @lead_provider1 = create(:lead_provider)
    @contract_period1 = create(:contract_period)
    @active_lead_provider1 = create(:active_lead_provider, lead_provider: @lead_provider1, contract_period: @contract_period1)
    @statement1 = create(:statement, active_lead_provider: @active_lead_provider1, year: 2024, month: 7)

    @lead_provider2 = create(:lead_provider)
    @contract_period2 = create(:contract_period)
    @active_lead_provider2 = create(:active_lead_provider, lead_provider: @lead_provider2, contract_period: @contract_period2)
    @statement2 = create(:statement, active_lead_provider: @active_lead_provider2, year: 2025, month: 5)
  end

  def when_i_visit_the_statement_page
    page.goto(admin_finance_statement_path(@statement1))
  end

  def then_i_should_see_statement_with_selected_options
    data = selector_options

    lead_provider_selected = data["Lead provider"].detect { |op| op[:selected] }[:value]
    expect(lead_provider_selected.to_i).to eq(@lead_provider1.id)

    contract_period_selected = data["Contract year"].detect { |op| op[:selected] }[:value]
    expect(contract_period_selected.to_i).to eq(@contract_period1.id)

    statement_date_selected = data["Statement date"].detect { |op| op[:selected] }[:value]
    expect(statement_date_selected).to eq([@statement1.year, @statement1.month].join("-"))
  end

  def when_i_select_a_different_statement
    selector = page.locator(".app-admin-filter")

    elem = selector.get_by_label("Lead provider", exact: true)
    elem.select_option(label: @lead_provider2.name)

    elem = selector.get_by_label("Contract year", exact: true)
    elem.select_option(label: @contract_period2.year.to_s)

    elem = selector.get_by_label("Statement date", exact: true)
    elem.select_option(label: "May 2025")

    selector.get_by_role('button', name: "View").click
  end

  def when_i_select_a_statement_that_does_not_exist
    selector = page.locator(".app-admin-filter")

    elem = selector.get_by_label("Lead provider", exact: true)
    elem.select_option(label: @lead_provider2.name)

    elem = selector.get_by_label("Contract year", exact: true)
    elem.select_option(label: @contract_period1.year.to_s)

    elem = selector.get_by_label("Statement date", exact: true)
    elem.select_option(label: "July 2024")

    selector.get_by_role('button', name: "View").click
  end

  def then_i_am_redirected_different_statement
    expect(page.url).to end_with(admin_finance_statement_path(@statement2))
  end

  def then_i_am_redirected_to_statement_not_found_page
    expect(page.get_by_text("No financial statements found")).to be_visible
    expect(page.url.split("?").first).to end_with(admin_finance_statements_path)
  end

  def selector_options
    page.query_selector_all(".app-admin-filter .filter-form-group").each_with_object({}) do |group, data|
      label = group.query_selector("label").text_content
      options = group.query_selector_all("option").map do |op|
        {
          value: op.get_attribute("value"),
          text: op.text_content,
          selected: (op.get_attribute("selected") == "selected"),
        }
      end

      data[label] = options
    end
  end
end
