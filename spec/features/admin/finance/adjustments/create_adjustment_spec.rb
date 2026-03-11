RSpec.describe "Create adjustment for statement" do
  include ActiveJob::TestHelper

  before { sign_in_as_dfe_user(role: :finance) }

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
    and_i_see_buttons_to_change_or_remove_the_adjustment
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
    expect(adjustments_table).to be_visible
  end

  def when_i_click_link(name)
    page.get_by_role("link", name:).click
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
      page.get_by_role("button", name:).click
    end
  end

  def and_i_see_adjustment_values
    expect(adjustments_table_values[0][0]).to eq("Test Payment")
    expect(adjustments_table_values[0][3]).to eq("£999.99")
  end

  def and_i_see_buttons_to_change_or_remove_the_adjustment
    expect(adjustments_table_values[0][1]).to eq("Change")
    expect(adjustments_table_values[0][2]).to eq("Remove")
  end

  def and_i_see_adjustment_total
    panel = page.locator(".finance-panel")

    total = panel.locator("table + .govuk-grid-row .govuk-grid-column-one-half").last

    expect(total).to have_text("Total")
    expect(total).to have_text("£999.99")
  end

  def and_an_adjustment_is_created
    adjustment = Statement::Adjustment.first
    expect(adjustment.statement).to eq(@statement)
    expect(adjustment.payment_type).to eq("Test Payment")
    expect(adjustment.amount).to eq(999.99)
  end

  def and_an_adjustment_added_event_is_recorded
    event = Event.find_by(event_type: "statement_adjustment_added")
    expect(event.statement).to eq(@statement)
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
