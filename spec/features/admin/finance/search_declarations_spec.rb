RSpec.describe "Admin finance search declarations" do
  include ActiveJob::TestHelper

  scenario "shows no results found when the declaration id does not match" do
    given_i_am_signed_in_as_a_finance_dfe_user
    when_i_visit_the_finance_page
    and_i_navigate_to_search_declarations
    when_i_search_for_a_declaration_id("non-existent-id")
    then_i_should_see_no_results_found
  end

  scenario "redirects to the teacher declarations page when the declaration id matches" do
    given_i_am_signed_in_as_a_finance_dfe_user
    and_a_declaration_exists_with_a_known_api_id
    when_i_visit_the_finance_page
    and_i_navigate_to_search_declarations
    when_i_search_for_a_declaration_id(@declaration.api_id)
    then_i_should_be_on_the_teacher_declarations_page
  end

  def given_i_am_signed_in_as_a_finance_dfe_user
    sign_in_as_dfe_user(role: :finance)
  end

  def and_a_declaration_exists_with_a_known_api_id
    @declaration = FactoryBot.create(:declaration)
  end

  def when_i_visit_the_finance_page
    page.goto(admin_finance_path)
  end

  def and_i_navigate_to_search_declarations
    page.get_by_role("link", name: "Search declarations", exact: true).click
    expect(page.get_by_role("heading", name: "Search declarations")).to be_visible
  end

  def when_i_search_for_a_declaration_id(declaration_id)
    page.get_by_label("Search for a declaration", exact: true).fill(declaration_id)
    page.get_by_role("button", name: "Search", exact: true).click
  end

  def then_i_should_see_no_results_found
    expect(page.get_by_text("No results found")).to be_visible
  end

  def then_i_should_be_on_the_teacher_declarations_page
    teacher = @declaration.ect_teacher || @declaration.mentor_teacher
    expect(page.url).to include(admin_teacher_declarations_path(teacher))
  end
end
