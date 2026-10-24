describe "Admin changing a deactivated teacher's TRN" do
  before do
    given_a_teacher_with_a_deactivated_trn
    given_the_replacement_trn_exists_in_trs

    sign_in_as_dfe_user(role: :user_manager)
  end

  it "replaces the TRN, preserves school history and shows the timeline event" do
    given_an_ect_registration

    when_i_start_the_change_trn_journey
    then_i_see_the_entry_page

    when_i_enter_the_replacement_trn
    then_i_see_the_proposed_change
    then_the_teacher_is_unchanged

    when_i_confirm_the_change
    then_i_see_the_success_page
    then_the_trn_is_replaced
    then_the_school_history_is_preserved

    when_i_return_to_the_teacher_list
    then_i_see_the_teacher_list

    when_i_view_the_teacher_overview
    then_the_change_trn_link_is_hidden

    when_i_view_the_timeline
    then_i_see_the_trn_change_event
  end

  it "shows validation errors for an invalid TRN and unchecked confirmation" do
    when_i_start_the_change_trn_journey

    when_i_continue_without_entering_a_trn
    then_i_see_the_trn_length_error

    when_i_enter_a_trn_that_is_too_short
    then_i_see_the_trn_length_error

    when_i_enter_the_replacement_trn
    then_i_see_the_proposed_change

    when_i_submit_without_confirming
    then_i_see_the_confirmation_error
    then_the_teacher_is_unchanged
  end

  it "allows cancellation from the entry page without changing the teacher" do
    when_i_start_the_change_trn_journey
    then_i_see_the_entry_page
    then_the_replacement_trn_field_is_empty

    when_i_cancel_the_change
    then_i_return_to_the_teacher_overview
    then_the_teacher_is_unchanged
  end

  it "allows cancellation from the confirm page without changing the teacher" do
    when_i_start_the_change_trn_journey
    when_i_enter_the_replacement_trn
    then_i_see_the_proposed_change

    when_i_cancel_the_change
    then_i_return_to_the_teacher_overview
    then_the_teacher_is_unchanged
  end

  context "when the replacement TRN already belongs to another RECT record" do
    before do
      given_two_teacher_records_with_school_history
    end

    it "merges the records, preserves school history and shows the timeline event" do
      when_i_start_the_change_trn_journey
      when_i_enter_the_replacement_trn
      then_i_see_the_merge_preview
      then_both_records_are_unchanged

      when_i_continue_to_merge_confirmation
      then_i_see_the_merge_confirmation

      when_i_confirm_the_merge
      then_i_see_the_merge_success_page
      then_the_records_are_merged

      when_i_return_to_the_teacher_list
      then_i_see_the_teacher_list

      when_i_view_the_destination_timeline
      then_i_see_the_merge_event
    end

    it "requires confirmation before merging" do
      when_i_start_the_change_trn_journey
      when_i_enter_the_replacement_trn
      when_i_continue_to_merge_confirmation

      when_i_submit_without_confirming
      then_i_see_the_merge_confirmation_error
      then_both_records_are_unchanged
    end

    it "allows cancellation from the merge preview" do
      when_i_start_the_change_trn_journey
      when_i_enter_the_replacement_trn
      then_i_see_the_merge_preview

      when_i_cancel_the_change
      then_i_return_to_the_teacher_overview
      then_both_records_are_unchanged
    end

    it "allows cancellation from merge confirmation" do
      when_i_start_the_change_trn_journey
      when_i_enter_the_replacement_trn
      when_i_continue_to_merge_confirmation
      then_i_see_the_merge_confirmation

      when_i_cancel_the_change
      then_i_return_to_the_teacher_overview
      then_both_records_are_unchanged
    end
  end

private

  def given_a_teacher_with_a_deactivated_trn
    @old_trn = "7654321"
    @new_trn = "2345678"

    @teacher = FactoryBot.create(
      :teacher,
      :deactivated_in_trs,
      trn: @old_trn,
      trs_first_name: "Bruce",
      trs_last_name: "Wayne"
    )
    @teacher_name = Teachers::Name.new(@teacher).full_name
  end

  def given_the_replacement_trn_exists_in_trs
    api_client = instance_double(TRS::APIClient)
    trs_teacher = instance_double(
      TRS::Teacher,
      trs_first_name: "Bruce",
      trs_last_name: "Wayne"
    )

    allow(TRS::APIClient).to receive(:build).and_return(api_client)
    allow(api_client).to receive(:find_teacher)
      .with(trn: @new_trn)
      .and_return(trs_teacher)
  end

  def given_an_ect_registration
    @school_period = FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      teacher: @teacher
    )
  end

  def when_i_start_the_change_trn_journey
    page.goto(admin_teacher_path(@teacher))
    page.get_by_role(
      "link",
      name: "Change the TRN for this deactivated record",
      exact: true
    ).click
  end

  def then_the_replacement_trn_field_is_empty
    expect(
      page.get_by_label("Enter the new TRN", exact: true)
    ).to have_value("")
  end

  def then_i_see_the_entry_page
    expect(
      page.get_by_role("heading", name: "Change TRN for deactivated record")
    ).to be_visible
  end

  def when_i_enter_the_replacement_trn
    page.get_by_label("Enter the new TRN", exact: true).fill(@new_trn)
    page.get_by_role("button", name: "Continue", exact: true).click
  end

  def then_i_see_the_proposed_change
    expect(
      page.get_by_role(
        "heading",
        name: "Confirm change of TRN for #{@teacher_name}"
      )
    ).to be_visible

    expect(page.get_by_text(@old_trn, exact: true)).to be_visible
    expect(page.get_by_text(@new_trn, exact: true)).to be_visible
  end

  def when_i_confirm_the_change
    page.get_by_label("I confirm I want to change this teacher’s TRN").check
    page.get_by_role("button", name: "Confirm", exact: true).click
  end

  def then_i_see_the_success_page
    expect(
      page.get_by_role("heading", name: "TRN changed for #{@teacher_name}")
    ).to be_visible

    expect(
      page.get_by_text("The old TRN has been deleted from the record.")
    ).to be_visible

    expect(page.get_by_text(@old_trn, exact: true)).to be_visible
    expect(page.get_by_text(@new_trn, exact: true)).to be_visible
  end

  def then_the_trn_is_replaced
    expect(@teacher.reload).to have_attributes(
      trn: @new_trn,
      trs_response: "ok",
      trs_redirected_to: nil
    )
  end

  def then_the_school_history_is_preserved
    expect(@school_period.reload.teacher_id).to eq(@teacher.id)
  end

  def when_i_return_to_the_teacher_list
    page.get_by_role("link", name: "Back to teachers", exact: true).click
  end

  def then_i_see_the_teacher_list
    expect(page).to have_url(admin_teachers_path)
  end

  def when_i_view_the_teacher_overview
    page.goto(admin_teacher_path(@teacher))
  end

  def then_the_change_trn_link_is_hidden
    expect(
      page.get_by_role("link", name: "Change the TRN for this deactivated record")
    ).not_to be_visible
  end

  def when_i_view_the_timeline
    page.get_by_role("link", name: "Timeline", exact: true).click
  end

  def then_i_see_the_trn_change_event
    expect(
      page.get_by_text(
        "TRN changed from '#{@old_trn}' to '#{@new_trn}'",
        exact: true
      )
    ).to be_visible

    event = @teacher.events.where(event_type: "teacher_trn_replaced").sole

    expect(event.author_type).to eq("dfe_staff_user")
  end

  def when_i_continue_without_entering_a_trn
    page.get_by_role("button", name: "Continue", exact: true).click
  end

  def when_i_enter_a_trn_that_is_too_short
    page.get_by_label("Enter the new TRN", exact: true).fill("1234")
    page.get_by_role("button", name: "Continue", exact: true).click
  end

  def then_i_see_the_trn_length_error
    expect(
      page.get_by_role(
        "link",
        name: "Teacher reference number must include at least 5 digits",
        exact: true
      )
    ).to be_visible
  end

  def when_i_submit_without_confirming
    page.get_by_role("button", name: "Confirm", exact: true).click
  end

  def then_i_see_the_confirmation_error
    expect(
      page.get_by_role(
        "link",
        name: "Confirm you want to change this teacher’s TRN",
        exact: true
      )
    ).to be_visible
  end

  def when_i_cancel_the_change
    page.get_by_role(
      "link",
      name: "Cancel and go back to #{@teacher_name}",
      exact: true
    ).click
  end

  def then_i_return_to_the_teacher_overview
    expect(page).to have_url(admin_teacher_path(@teacher))
  end

  def then_the_teacher_is_unchanged
    expect(@teacher.reload).to have_attributes(
      trn: @old_trn,
      trs_response: "gone"
    )
    expect(
      @teacher.events.where(event_type: "teacher_trn_replaced").exists?
    ).to be(false)
  end

  def given_two_teacher_records_with_school_history
    @destination = FactoryBot.create(
      :teacher,
      trn: @new_trn,
      trs_response: "ok",
      trs_first_name: "Bruce",
      trs_last_name: "Wayne"
    )
    @destination_name = Teachers::Name.new(@destination).full_name

    @source_school_period = FactoryBot.create(
      :ect_at_school_period,
      teacher: @teacher,
      started_on: Date.new(2025, 9, 1),
      finished_on: Date.new(2025, 12, 1)
    )

    @destination_school_period = FactoryBot.create(
      :ect_at_school_period,
      teacher: @destination,
      started_on: Date.new(2026, 1, 1),
      finished_on: nil
    )
  end

  def then_i_see_the_merge_preview
    expect(
      page.get_by_role(
        "heading",
        name: "Check teacher records before merging",
        exact: true
      )
    ).to be_visible

    expect(page.get_by_text(@old_trn, exact: true)).to be_visible
    expect(page.get_by_text(@new_trn, exact: true)).to be_visible

    expect(
      page.get_by_text(@source_school_period.school.name, exact: true).first
    ).to be_visible

    expect(
      page.get_by_text(@destination_school_period.school.name, exact: true).first
    ).to be_visible
  end

  def when_i_continue_to_merge_confirmation
    page.get_by_role("button", name: "Continue", exact: true).click
  end

  def then_i_see_the_merge_confirmation
    expect(
      page.get_by_role(
        "heading",
        name: "Confirm merge for #{@teacher_name}",
        exact: true
      )
    ).to be_visible

    expect(page.get_by_text(@old_trn, exact: true)).to be_visible
    expect(page.get_by_text(@new_trn, exact: true)).to be_visible
  end

  def when_i_confirm_the_merge
    page.get_by_label(
      "I confirm I want to merge these teacher records",
      exact: true
    ).check

    page.get_by_role("button", name: "Confirm", exact: true).click
  end

  def then_i_see_the_merge_success_page
    expect(
      page.get_by_role("heading", name: "Records merged", exact: true)
    ).to be_visible

    expect(
      page.get_by_role("link", name: "Back to teachers", exact: true)
    ).to be_visible
  end

  def then_the_records_are_merged
    expect(Teacher.exists?(@teacher.id)).to be(false)
    expect(@destination.reload.trn).to eq(@new_trn)

    expect(@source_school_period.reload.teacher_id).to eq(@destination.id)
    expect(@destination_school_period.reload.teacher_id).to eq(@destination.id)

    expect(@source_school_period).to have_attributes(
      started_on: Date.new(2025, 9, 1),
      finished_on: Date.new(2025, 12, 1)
    )
    expect(@destination_school_period).to have_attributes(
      started_on: Date.new(2026, 1, 1),
      finished_on: nil
    )
  end

  def when_i_view_the_destination_timeline
    page.goto(admin_teacher_path(@destination))
    page.get_by_role("link", name: "Timeline", exact: true).click
  end

  def then_i_see_the_merge_event
    expect(
      page.get_by_text(
        "Records were merged into #{@destination_name} from #{@teacher_name}",
        exact: true
      )
    ).to be_visible

    event = @destination.events.where(event_type: "teacher_merged").sole

    expect(event.author_type).to eq("dfe_staff_user")
  end

  def then_i_see_the_merge_confirmation_error
    expect(
      page.get_by_role(
        "link",
        name: "Confirm you want to merge these teacher records",
        exact: true
      )
    ).to be_visible
  end

  def then_both_records_are_unchanged
    then_the_teacher_is_unchanged

    expect(@destination.reload.trn).to eq(@new_trn)
    expect(@source_school_period.reload.teacher_id).to eq(@teacher.id)
    expect(@destination_school_period.reload.teacher_id).to eq(@destination.id)

    expect(
      @destination.events.where(event_type: "teacher_merged").exists?
    ).to be(false)
  end
end
