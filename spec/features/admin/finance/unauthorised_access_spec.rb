RSpec.describe "Unauthorised access to finance section" do
  before { sign_in_as_dfe_user(role: :admin) }

  scenario "Non-finance DfE user cannot access the finance landing page" do
    when_i_visit_the_finance_landing_page
    then_i_see_the_finance_unauthorised_message
  end

  scenario "Non-finance DfE user cannot access finance statements via direct link" do
    when_i_visit_the_finance_statements_page
    then_i_see_the_finance_unauthorised_message
  end

  def when_i_visit_the_finance_landing_page
    page.goto(admin_finance_path)
  end

  def when_i_visit_the_finance_statements_page
    page.goto(admin_finance_statements_path)
  end

  def then_i_see_the_finance_unauthorised_message
    expect(page.get_by_text(
             "This is to access financial information for Register early career teachers. To gain access, contact the product team."
           )).to be_visible
  end
end
