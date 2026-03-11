RSpec.describe "Delete adjustment from statement" do
  include ActiveJob::TestHelper

  before { sign_in_as_dfe_user(role: :finance) }

  scenario "Delete adjustment" do
    given_a_finance_statement_exists
    and_the_statement_has_adjustments

    when_i_visit_the_finance_statement_page
    then_i_see_adjustments_section
    and_i_see_adjustment_values
    and_i_see_adjustment_total

    when_i_click_delete_adjustment_link

    then_i_see("Are you sure you want to remove the '#{@deleted_adjustment.payment_type}' adjustment?")
    and_i_click_button("Remove adjustment")

    then_i_see_adjustments_section
    and_i_see_a_sucess_banner
    and_i_see_new_adjustment_values
    and_i_see_new_adjustment_total
    and_deleted_adjustment_should_not_exist
    and_an_adjustment_deleted_event_is_recorded
  end

  def given_a_finance_statement_exists
    @statement = FactoryBot.create(:statement)
  end

  def when_i_visit_the_finance_statement_page
    page.goto(admin_finance_statement_path(@statement))
  end

  def and_the_statement_has_adjustments
    FactoryBot.create(:statement_adjustment, statement: @statement, payment_type: "Amount 1", amount: 100.0)
    @deleted_adjustment = FactoryBot.create(:statement_adjustment, statement: @statement, payment_type: "Amount 2", amount: -150.0)
    FactoryBot.create(:statement_adjustment, statement: @statement, payment_type: "Amount 3", amount: 500.0)
  end

  def and_i_see_adjustment_values
    expect(adjustments_table_values[0][0]).to eq("Amount 1")
    expect(adjustments_table_values[0][2]).to eq("£100.00")

    expect(adjustments_table_values[1][0]).to eq("Amount 2")
    expect(adjustments_table_values[1][2]).to eq("-£150.00")

    expect(adjustments_table_values[2][0]).to eq("Amount 3")
    expect(adjustments_table_values[2][2]).to eq("£500.00")
  end

  def and_i_see_adjustment_total
    panel = page.locator(".finance-panel")

    total = panel.locator("table + .govuk-grid-row .govuk-grid-column-one-half").last

    expect(total).to have_text("Total")
    expect(total).to have_text("£450.00")
  end

  def and_i_see_new_adjustment_values
    @adjustments_table_values = nil # clear memoized values

    expect(adjustments_table_values[0][0]).to eq("Amount 1")
    expect(adjustments_table_values[0][2]).to eq("£100.00")

    expect(adjustments_table_values[1][0]).to eq("Amount 3")
    expect(adjustments_table_values[1][2]).to eq("£500.00")
  end

  def and_i_see_new_adjustment_total
    panel = page.locator(".finance-panel")

    total = panel.locator("table + .govuk-grid-row .govuk-grid-column-one-half").last

    expect(total).to have_text("Total")
    expect(total).to have_text("£600.00")
  end

  def then_i_see_adjustments_section
    expect(adjustments_table).to be_visible
  end

  def when_i_click_delete_adjustment_link
    row = adjustments_table.locator("tbody tr").nth(1)
    expect(row).to have_text(/Amount 2/)
    row.get_by_role("link", name: "Remove").click
  end

  def and_deleted_adjustment_should_not_exist
    expect(page.get_by_text(@deleted_adjustment.payment_type)).not_to be_visible
    expect(Statement::Adjustment.count).to be(2)
    expect(Statement::Adjustment.where(id: @deleted_adjustment.id).count).to be(0)
  end

  def and_i_see_a_sucess_banner
    expect(page.locator(".govuk-notification-banner"))
      .to have_text("Adjustment removed")
  end

  def then_i_see(string)
    expect(page.get_by_text(string)).to be_visible
  end

  def and_i_click_button(name)
    perform_enqueued_jobs do
      page.get_by_role("button", name:).click
    end
  end

  def and_an_adjustment_deleted_event_is_recorded
    event = Event.find_by(event_type: "statement_adjustment_deleted")
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
