RSpec.describe "List adjustments for statement" do
  before { sign_in_as_dfe_user(role: :finance) }

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
    @statement = FactoryBot.create(:statement, :service_fee)
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
    expect(adjustments_table).to be_visible
  end

  def and_i_see_adjustment_values
    expect(adjustments_table_values[0][0]).to eq("Amount 1")
    expect(adjustments_table_values[0][3]).to eq("£100.00")

    expect(adjustments_table_values[1][0]).to eq("Amount 2")
    expect(adjustments_table_values[1][3]).to eq("-£150.00")

    expect(adjustments_table_values[2][0]).to eq("Amount 3")
    expect(adjustments_table_values[2][3]).to eq("£500.00")
  end

  def and_i_see_adjustment_total
    panel = adjustments_table.locator("xpath=ancestor::div[contains(@class,'finance-panel')]")

    adjustments_total = panel.locator(".govuk-heading-s").all.map { |e| e.text_content.strip }

    expect(adjustments_total).to eq(["Total", "£450.00"])
  end

  def and_i_should_not_see_add_adjustment_link
    expect(page.get_by_role("link", name: "Add adjustment")).not_to be_visible
  end

  def when_i_visit_new_adjustment_page_directly
    page.goto(new_admin_finance_statement_adjustment_path(@statement))
  end

  def then_i_am_redirected_back_to_finance_statement_page
    expect(page).to have_path(admin_finance_statement_path(@statement))
  end

  def adjustments_table_values
    @adjustments_table_values ||=
      adjustments_table.locator("tbody tr").all.map do |row|
        row.locator("td").all.map { |cell| cell.text_content.strip }
      end
  end

  def adjustments_table
    page.get_by_role("table", name: "Additional adjustments")
  end
end
