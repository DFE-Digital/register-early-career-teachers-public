RSpec.describe "Update adjustment for statement" do
  include ActiveJob::TestHelper

  before { sign_in_as_dfe_user(role: :admin) }

  scenario "Update adjustment" do
    given_a_finance_statement_exists
    and_the_statement_has_adjustments

    when_i_visit_the_finance_statement_page
    then_i_see_adjustments_section
    and_i_see_adjustment_values
    and_i_see_adjustment_total

    when_i_click_change_adjustment_link

    then_i_see("Change adjustment")

    when_i_fill_in(label: "Adjustment name", value: "Big amount")
    and_i_fill_in(label: "Adjustment amount", value: "10000")
    and_i_click_button("Save changes")

    then_i_see_adjustments_section
    and_i_see_new_adjustment_values
    and_i_see_new_adjustment_total
    and_adjustment_should_have_been_updated
    and_an_adjustment_updated_event_is_recorded
  end

  def given_a_finance_statement_exists
    @statement = create(:statement)
  end

  def when_i_visit_the_finance_statement_page
    page.goto(admin_finance_statement_path(@statement))
  end

  def and_the_statement_has_adjustments
    create(:statement_adjustment, statement: @statement, payment_type: "Amount 1", amount: 100.0)
    @changed_adjustment = create(:statement_adjustment, statement: @statement, payment_type: "Amount 2", amount: -150.0)
    create(:statement_adjustment, statement: @statement, payment_type: "Amount 3", amount: 500.0)
  end

  def and_i_see_adjustment_values
    values = summary_list_values
    expect(values[0][0]).to eq("Amount 1")
    expect(values[0][1]).to eq("£100.00")

    expect(values[1][0]).to eq("Amount 2")
    expect(values[1][1]).to eq("-£150.00")

    expect(values[2][0]).to eq("Amount 3")
    expect(values[2][1]).to eq("£500.00")
  end

  def and_i_see_adjustment_total
    values = summary_list_values
    expect(values.last[0]).to eq("Total")
    expect(values.last[1]).to eq("£450.00")
  end

  def and_i_see_new_adjustment_values
    values = summary_list_values
    expect(values[0][0]).to eq("Amount 1")
    expect(values[0][1]).to eq("£100.00")

    expect(values[1][0]).to eq("Big amount")
    expect(values[1][1]).to eq("£10,000.00")

    expect(values[2][0]).to eq("Amount 3")
    expect(values[2][1]).to eq("£500.00")
  end

  def and_i_see_new_adjustment_total
    values = summary_list_values
    expect(values.last[0]).to eq("Total")
    expect(values.last[1]).to eq("£10,600.00")
  end

  def then_i_see_adjustments_section
    expect(page.locator('#adjustments.govuk-summary-card h2').text_content).to eq("Additional adjustments")
  end

  def when_i_click_change_adjustment_link
    # second adjustment
    page.locator('#adjustments.govuk-summary-card .govuk-summary-list .govuk-summary-list__row:nth-child(2)').get_by_role('link', name: "Change adjustment").click
  end

  def and_adjustment_should_have_been_updated
    @changed_adjustment.reload
    expect(@changed_adjustment.payment_type).to eq("Big amount")
    expect(@changed_adjustment.amount).to eq(10_000.0)
    expect(Statement::Adjustment.count).to eq(3)
  end

  def summary_list_values
    page.query_selector_all("#adjustments.govuk-summary-card .govuk-summary-list .govuk-summary-list__row").map do |row|
      row.query_selector_all(".govuk-summary-list__key, .govuk-summary-list__value").map { |v| v.text_content.strip }
    end
  end

  def then_i_see(string)
    expect(page.get_by_text(string)).to be_visible
  end

  def when_i_fill_in(label:, value:)
    page.get_by_label(label, exact: true).fill(value.to_s)
  end

  alias_method :and_i_fill_in, :when_i_fill_in

  def and_i_click_button(name)
    perform_enqueued_jobs do
      page.get_by_role('button', name:).click
    end
  end

  def and_an_adjustment_updated_event_is_recorded
    event = Event.find_by(event_type: "statement_adjustment_updated")
    expect(event.statement).to eq(@statement)
  end
end
