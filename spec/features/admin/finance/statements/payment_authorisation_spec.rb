RSpec.describe "Payment authorisation for statement" do
  before { sign_in_as_dfe_user(role: :admin) }

  scenario "Statement can be authorised for payment" do
    given_a_payable_finance_statement_exists

    when_i_visit_the_finance_statement_page
    and_i_click_authorise_for_payment_button

    then_i_see_payment_authorised_notice
    and_i_see_payment_authorised_text
    and_statement_is_payment_authorised
  end

  def given_a_payable_finance_statement_exists
    @statement = FactoryBot.create(:statement, :payable, :output_fee, marked_as_paid_at: nil, deadline_date: 3.days.ago.to_date)
  end

  def when_i_visit_the_finance_statement_page
    page.goto(admin_finance_statement_path(@statement))
  end

  def and_i_click_authorise_for_payment_button
    page.get_by_role('button', name: "Authorise for payment").click
  end

  def then_i_see_payment_authorised_notice
    expect(page.get_by_text('Statement authorised')).to be_visible
  end

  def and_i_see_payment_authorised_text
    marked_as_paid_at = @statement.reload.marked_as_paid_at.in_time_zone("London").strftime("%-I:%M%P on %-e %B %Y")
    expect(page.get_by_text("Authorised for payment at #{marked_as_paid_at}")).to be_visible
  end

  def and_statement_is_payment_authorised
    expect(@statement.marked_as_paid_at).to be_present
    expect(@statement.status).to eq("paid")
  end
end
