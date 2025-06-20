RSpec.describe "List adjustments for statement" do
  before { sign_in_as_dfe_user(role: :admin) }

  scenario "Statement with adjustments" do
    given_a_finance_statement_exists
    and_the_statement_has_adjustments

    when_i_visit_the_finance_statement_page

    then_i_see_adjustments_section
    and_i_see_adjustment_values
    and_i_see_adjustment_total
  end

  scenario "Statement is payable or paid" do
    given_a_closed_finance_statement_exists
    when_i_visit_the_finance_statement_page

    then_i_see_adjustments_section
    and_i_should_not_see_add_adjustment_link

    when_i_visit_new_adjustment_page_directly
    then_i_am_redirected_back_to_finance_statement_page
  end

  scenario "Statement has false output_fee" do
    given_a_finance_statement_with_false_output_fees_exists
    when_i_visit_the_finance_statement_page

    then_i_see_adjustments_section
    and_i_should_not_see_add_adjustment_link

    when_i_visit_new_adjustment_page_directly
    then_i_am_redirected_back_to_finance_statement_page
  end

  def given_a_finance_statement_exists
    @statement = FactoryBot.create(:statement)
  end

  def given_a_closed_finance_statement_exists
    @statement = FactoryBot.create(:statement, :paid)
  end

  def given_a_finance_statement_with_false_output_fees_exists
    @statement = FactoryBot.create(:statement, output_fee: false)
  end

  def when_i_visit_the_finance_statement_page
    page.goto(admin_finance_statement_path(@statement))
  end

  def and_the_statement_has_adjustments
    FactoryBot.create(:statement_adjustment, statement: @statement, payment_type: "Amount 1", amount: 100.0)
    FactoryBot.create(:statement_adjustment, statement: @statement, payment_type: "Amount 2", amount: -150.0)
    FactoryBot.create(:statement_adjustment, statement: @statement, payment_type: "Amount 3", amount: 500.0)
  end

  def then_i_see_adjustments_section
    expect(page.locator('#adjustments.govuk-summary-card h2').text_content).to eq("Additional adjustments")
  end

  def and_i_see_adjustment_values
    expect(summary_list_values[0][0]).to eq("Amount 1")
    expect(summary_list_values[0][1]).to eq("£100.00")

    expect(summary_list_values[1][0]).to eq("Amount 2")
    expect(summary_list_values[1][1]).to eq("-£150.00")

    expect(summary_list_values[2][0]).to eq("Amount 3")
    expect(summary_list_values[2][1]).to eq("£500.00")
  end

  def and_i_see_adjustment_total
    expect(summary_list_values.last[0]).to eq("Total")
    expect(summary_list_values.last[1]).to eq("£450.00")
  end

  def and_i_should_not_see_add_adjustment_link
    expect(page.get_by_role('link', name: "Add adjustment")).not_to be_visible
  end

  def when_i_visit_new_adjustment_page_directly
    page.goto(new_admin_finance_statement_adjustment_path(@statement))
  end

  def then_i_am_redirected_back_to_finance_statement_page
    expect(page.url).to end_with(admin_finance_statement_path(@statement))
  end

  def summary_list_values
    @summary_list_values ||=
      page.query_selector_all("#adjustments.govuk-summary-card .govuk-summary-list .govuk-summary-list__row").map do |row|
        row.query_selector_all(".govuk-summary-list__key, .govuk-summary-list__value").map { |v| v.text_content.strip }
      end
  end
end
