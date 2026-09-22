describe "Admin undoing a registration" do
  before do
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "Bruce",
      trs_last_name: "Wayne"
    )
    @teacher_name = Teachers::Name.new(@teacher).full_name

    sign_in_as_dfe_user(role: :admin)
  end

  it "closes an ECT registration with declarations" do
    given_an_ect_registration_with_declarations

    when_i_start_the_undo_registration_journey
    then_i_see_the_close_confirmation

    when_i_confirm_the_undo(action: "close")
    then_i_see_the_registration_undone_confirmation(action: "closed")
  end

  it "deletes a mentor registration without declarations" do
    given_a_mentor_registration_without_declarations

    when_i_start_the_undo_registration_journey
    then_i_see_the_delete_confirmation

    when_i_confirm_the_undo(action: "delete")
    then_i_see_the_registration_undone_confirmation(action: "deleted")
  end

  it "allows an admin to select a registration when the teacher has multiple school periods" do
    given_an_ect_and_a_mentor_registration

    when_i_start_the_undo_registration_journey
    then_i_see_the_school_period_selection

    when_i_select_the_ect_registration
    then_i_see_the_close_confirmation

    when_i_confirm_the_undo(action: "close")
    then_i_see_the_registration_undone_confirmation(action: "closed")
  end

private

  def given_an_ect_registration_with_declarations
    @ect_at_school_period = FactoryBot.create(:ect_at_school_period, :unfinished, teacher: @teacher)
    training_period = FactoryBot.create(
      :training_period,
      :for_ect,
      :unfinished,
      ect_at_school_period: @ect_at_school_period
    )
    FactoryBot.create(:declaration, :eligible, training_period:)
  end

  def given_a_mentor_registration_without_declarations
    mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :unfinished, teacher: @teacher)
    FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period:)
  end

  def given_an_ect_and_a_mentor_registration
    given_an_ect_registration_with_declarations
    FactoryBot.create(:mentor_at_school_period, :unfinished, teacher: @teacher)
  end

  def when_i_start_the_undo_registration_journey
    page.goto(admin_teacher_school_path(@teacher))
    page.get_by_role("link", name: "Undo a registration for #{@teacher_name}").click
    page.get_by_role("link", name: "Continue").click
  end

  def then_i_see_the_close_confirmation
    expect(
      page.get_by_role("heading", name: "Confirm undo registration and close school periods for #{@teacher_name}")
    ).to be_visible
  end

  def then_i_see_the_delete_confirmation
    expect(
      page.get_by_role("heading", name: "Confirm undo registration and delete school periods for #{@teacher_name}")
    ).to be_visible
  end

  def when_i_confirm_the_undo(action:)
    page.get_by_label(
      "I confirm I want to undo this registration and #{action} these school and training periods"
    ).check
    page.get_by_role("button", name: "Confirm").click
  end

  def then_i_see_the_registration_undone_confirmation(action:)
    expect(page.get_by_text("Registration undone")).to be_visible
    expect(page.get_by_text("Associated school, training, and mentorship periods have been #{action}.")).to be_visible
  end

  def then_i_see_the_school_period_selection
    expect(page.get_by_role("heading", name: "Select a school period to undo for #{@teacher_name}")).to be_visible
  end

  def when_i_select_the_ect_registration
    page.get_by_label(@ect_at_school_period.school.name).check
    page.get_by_role("button", name: "Continue").click
  end
end
