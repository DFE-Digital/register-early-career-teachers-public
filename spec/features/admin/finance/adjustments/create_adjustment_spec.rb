RSpec.describe "Create adjustment for statement" do
  include ActiveJob::TestHelper

  before { sign_in_as_dfe_user(role: :admin) }

  scenario "Add new adjustment" do
    given_a_finance_statement_exists
    when_i_visit_the_finance_statement_page
    then_i_see_adjustments_section

    when_i_click_link("Add adjustment")

    then_i_see("Make adjustment")

    when_i_fill_in(label: "Adjustment name", value: "Test Payment")
    and_i_fill_in(label: "Adjustment amount", value: "999.99")
    and_i_click_button("Add adjustment")

    then_i_see_adjustments_section
    and_i_see_adjustment_values
    and_i_see_adjustment_total
    and_an_adjustment_is_created
    and_an_adjustment_added_event_is_recorded
  end

  def given_a_finance_statement_exists
    @statement = FactoryBot.create(:statement)
  end

  def when_i_visit_the_finance_statement_page
    page.goto(admin_finance_statement_path(@statement))
  end

  def then_i_see_adjustments_section
    expect(page.locator('#adjustments.govuk-summary-card h2').text_content).to eq("Additional adjustments")
  end

  def when_i_click_link(name)
    page.get_by_role('link', name:).click
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

  def and_i_see_adjustment_values
    expect(summary_list_values[0][0]).to eq("Test Payment")
    expect(summary_list_values[0][1]).to eq("£999.99")
  end

  def and_i_see_adjustment_total
    expect(summary_list_values.last[0]).to eq("Total")
    expect(summary_list_values.last[1]).to eq("£999.99")
  end

  def and_an_adjustment_is_created
    adjustment = Statement::Adjustment.first
    expect(adjustment.statement).to eq(@statement)
    expect(adjustment.payment_type).to eq("Test Payment")
    expect(adjustment.amount).to eq(999.99)
  end

  def summary_list_values
    @summary_list_values ||=
      page.query_selector_all("#adjustments.govuk-summary-card .govuk-summary-list .govuk-summary-list__row").map do |row|
        row.query_selector_all(".govuk-summary-list__key, .govuk-summary-list__value").map { |v| v.text_content.strip }
      end
  end

  def and_an_adjustment_added_event_is_recorded
    event = Event.find_by(event_type: "statement_adjustment_added")
    expect(event.statement).to eq(@statement)
  end
end
