RSpec.describe "Admin importing an ECT" do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before { sign_in_as_dfe_user(role: :admin, user: admin_user) }

  scenario '"Import TRS record" button is available on Admin homepage' do
    given_i_am_on_the_admin_teachers_index_page
    then_i_should_see_the_import_ect_button
  end

  describe "eligible import" do
    include_context "test TRS API returns a teacher"

    scenario "the teacher can be imported" do
      given_i_am_on_the_admin_teachers_index_page
      when_i_click_the_import_ect_button

      then_i_should_be_on_the_find_ect_page
      when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
      and_i_click_continue

      then_i_should_be_on_the_check_ect_page
      and_i_should_see_the_ect_details
      when_i_click_continue

      then_i_should_be_on_the_register_ect_page
      and_i_should_see_the_success_message
      and_the_teacher_should_be_created_in_the_database
      and_no_induction_period_should_be_created
    end
  end

  describe "ineligible import" do
    context "when teacher is not found in TRS" do
      include_context "test TRS API returns nothing"

      scenario "displays an error" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_do_not_exist_in_trs
        and_i_click_continue
        then_i_should_see_the_teacher_not_found_error
      end
    end

    context "when teacher already exists in the service" do
      include_context "test TRS API returns a teacher"

      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: "1234567") }

      scenario "redirects to existing teacher page" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_for_existing_teacher
        and_i_click_continue
        then_i_should_be_redirected_to_the_existing_teacher_induction_page
        and_i_should_see_the_teacher_already_exists_message
      end
    end

    context "when teacher does not have QTS" do
      include_context "test TRS API returns a teacher without QTS"

      scenario "the teacher cannot be imported" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue
        then_i_should_be_on_the_check_ect_page
        and_i_should_see_the_error_message("Kirk Van Houten does not have their qualified teacher status (QTS).")
        and_i_should_not_see_the_continue_button
      end
    end

    context "when teacher is prohibited from teaching" do
      include_context "test TRS API returns a teacher prohibited from teaching"

      scenario "the teacher cannot be imported" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue
        then_i_should_be_on_the_check_ect_page
        and_i_should_see_the_error_message("Kirk Van Houten is prohibited from teaching.")
        and_i_should_not_see_the_continue_button
      end
    end

    context "when the teacher is exempt" do
      include_context "test TRS API returns a teacher with specific induction status", "Exempt"

      scenario "the teacher cannot be imported" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue
        then_i_should_be_on_the_check_ect_page
        and_i_should_see_the_error_message("Kirk Van Houten is exempt from completing their induction.")
        and_i_should_not_see_the_continue_button
      end
    end

    context "when the teacher has passed their induction" do
      include_context "test TRS API returns a teacher with specific induction status", "Passed"

      scenario "the teacher cannot be imported" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue
        then_i_should_be_on_the_check_ect_page
        and_i_should_see_the_error_message("Kirk Van Houten has already passed their induction.")
        and_i_should_not_see_the_continue_button
      end
    end

    context "when the teacher has failed their induction" do
      include_context "test TRS API returns a teacher with specific induction status", "Failed"

      scenario "the teacher cannot be imported" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue
        then_i_should_be_on_the_check_ect_page
        and_i_should_see_the_error_message("Kirk Van Houten has already failed their induction.")
        and_i_should_not_see_the_continue_button
      end
    end

    context "when the teacher has failed their induction (in Wales)" do
      include_context "test TRS API returns a teacher with specific induction status", "FailedInWales"

      scenario "the teacher cannot be imported" do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue
        then_i_should_be_on_the_check_ect_page
        and_i_should_see_the_error_message("Kirk Van Houten has already failed their induction.")
        and_i_should_not_see_the_continue_button
      end
    end
  end

private

  def given_i_am_on_the_admin_teachers_index_page
    path = "/admin/teachers"
    page.goto(path)
    expect(page).to have_path(path)
  end

  def given_i_am_on_the_find_ect_page
    path = "/admin/import-ect/find-ect/new"
    page.goto(path)
    expect(page).to have_path(path)
  end

  def then_i_should_see_the_import_ect_button
    expect(page.get_by_role("link", name: "Import TRS record")).to be_visible
  end

  def when_i_click_the_import_ect_button
    page.get_by_role("link", name: "Import TRS record").click
  end

  def then_i_should_be_on_the_find_ect_page
    expect(page).to have_path("/admin/import-ect/find-ect/new")
    expect(page.get_by_text("Find an early career teacher")).to be_visible
  end

  def when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
    page.get_by_label("Teacher reference number").fill("1234567")
    page.get_by_label("Day").fill("1")
    page.get_by_label("Month").fill("2")
    page.get_by_label("Year").fill("2003")
  end

  def when_i_enter_a_trn_and_date_of_birth_that_do_not_exist_in_trs
    page.get_by_label("Teacher reference number").fill("9999999")
    page.get_by_label("Day").fill("1")
    page.get_by_label("Month").fill("2")
    page.get_by_label("Year").fill("2003")
  end

  def when_i_enter_a_trn_for_existing_teacher
    page.get_by_label("Teacher reference number").fill("1234567")
    page.get_by_label("Day").fill("1")
    page.get_by_label("Month").fill("2")
    page.get_by_label("Year").fill("2003")
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_on_the_check_ect_page
    @pending_induction_submission = PendingInductionSubmission.last
    path = "/admin/import-ect/check-ect/#{@pending_induction_submission.id}/edit"
    expect(page).to have_path(path)
  end

  def and_i_should_see_the_ect_details
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("1234567")).to be_visible
    expect(page.get_by_text("1 February 2003")).to be_visible
  end

  def when_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_on_the_register_ect_page
    path = "/admin/import-ect/register-ect/#{@pending_induction_submission.id}"
    expect(page).to have_path(path)
  end

  def and_i_should_see_the_success_message
    expect(page.get_by_text("You've successfully imported Kirk Van Houten's induction")).to be_visible
  end

  def and_the_teacher_should_be_created_in_the_database
    teacher = Teacher.find_by(trn: "1234567")
    expect(teacher).to be_present
    expect(teacher.trs_first_name).to eq("Kirk")
    expect(teacher.trs_last_name).to eq("Van Houten")
  end

  def and_no_induction_period_should_be_created
    expect(InductionPeriod.count).to eq(0)
  end

  def then_i_should_see_the_teacher_not_found_error
    expect(page.get_by_text("No teacher with this TRN and date of birth was found")).to be_visible
  end

  def then_i_should_be_redirected_to_the_existing_teacher_induction_page
    teacher = Teacher.find_by(trn: "1234567")
    expect(page).to have_path("/admin/teachers/#{teacher.id}/induction")
  end

  def and_i_should_see_the_teacher_already_exists_message
    teacher = Teacher.find_by(trn: "1234567")
    expect(page.get_by_text("Teacher #{teacher.trn} already exists in the system")).to be_visible
  end

  def and_i_should_see_the_error_message(message)
    expect(page.get_by_text("You cannot register Kirk Van Houten.")).to be_visible
    expect(page.get_by_text(message)).to be_visible
  end

  def and_i_should_not_see_the_continue_button
    expect(page.get_by_role("button", name: "Continue")).not_to be_visible
  end
end
