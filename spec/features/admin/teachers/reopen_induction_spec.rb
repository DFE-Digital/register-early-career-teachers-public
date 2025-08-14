describe "Admins can reopen a teacher's closed induction" do
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    FactoryBot.create(:induction_period, :pass, teacher:)
    sign_in_as_dfe_user(role: :admin)
  end

  it "reopens the induction period" do
    when_i_go_to_the_teacher_page
    then_there_is_no_current_induction_period

    when_i_reopen_the_induction
    and_i_am_sure_i_want_to_reopen_the_induction
    then_the_induction_is_successfully_reopened
    and_there_is_a_current_induction_period
  end

private

  def when_i_go_to_the_teacher_page
    page.goto(admin_teacher_path(teacher))
  end

  def then_there_is_no_current_induction_period
    expect(page.locator("h2", hasText: "Current induction period"))
      .not_to be_visible
  end

  def when_i_reopen_the_induction
    page.get_by_role("link", name: "Reopen induction").click
  end

  def and_i_am_sure_i_want_to_reopen_the_induction
    expect(page.locator(".govuk-warning-text"))
      .to have_text("Are you sure you want to reopen this induction?")

    page.get_by_role("button", name: "Reopen induction").click
  end

  def then_the_induction_is_successfully_reopened
    expect(page.locator(".govuk-notification-banner__content"))
      .to have_text("Induction was successfully reopened")
  end

  def and_there_is_a_current_induction_period
    expect(page.locator("h2", hasText: "Current induction period"))
      .to be_visible
  end
end
