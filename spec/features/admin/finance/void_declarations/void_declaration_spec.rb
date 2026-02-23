RSpec.describe "Void a declaration" do
  before { sign_in_as_dfe_user(role: :finance) }

  scenario "Void an unpaid declaration" do
    given_a_declaration_exists
    and_a_future_output_fee_statement_exists

    when_i_visit_the_teacher_declarations_page
    and_i_click_void_declaration
    then_i_see_the_confirmation_page

    when_i_click_confirm_void_declaration
    then_i_see_the_success_message
    and_the_declaration_is_voided
  end

private

  def given_a_declaration_exists
    @declaration = FactoryBot.create(:declaration, :no_payment)
    @teacher = @declaration.teacher
  end

  def and_a_future_output_fee_statement_exists
    active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider: @declaration.training_period.lead_provider, contract_period: @declaration.training_period.contract_period)
    FactoryBot.create(:statement, :output_fee, active_lead_provider:)
  end

  def when_i_visit_the_teacher_declarations_page
    page.goto(admin_teacher_declarations_path(@teacher))
  end

  def and_i_click_void_declaration
    page.locator("summary").get_by_text(@declaration.api_id).click
    page.get_by_role("link", name: "Void declaration").click
  end

  def then_i_see_the_confirmation_page
    expect(page.get_by_text("Void declaration for")).to be_visible
    expect(page.get_by_text(@declaration.api_id)).to be_visible
    expect(page.get_by_role("button", name: "Confirm void declaration")).to be_visible
  end

  def when_i_click_confirm_void_declaration
    page.get_by_label("I confirm I want to void this declaration").check
    page.get_by_role("button", name: "Confirm void declaration").click
  end

  def then_i_see_the_success_message
    expect(page.get_by_text("Declaration voided")).to be_visible
  end

  def and_the_declaration_is_voided
    expect(@declaration.reload.payment_status).to eq("voided")
  end
end
