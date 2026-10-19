describe "Admin changing a deactivated teacher's TRN" do
  before do
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

    sign_in_as_dfe_user(role: :user_manager)
  end

  it "replaces the TRN, preserves school history and shows the timeline event" do
    school_period = FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      teacher: @teacher
    )

    when_i_start_the_change_trn_journey
    when_i_enter_the_replacement_trn

    expect(page.get_by_text(@old_trn, exact: true)).to be_visible
    expect(page.get_by_text(@new_trn, exact: true)).to be_visible

    expect(@teacher.reload.trn).to eq(@old_trn)

    page.get_by_label("I confirm I want to change this teacher’s TRN").check
    page.get_by_role("button", name: "Confirm", exact: true).click

    expect(
      page.get_by_role("heading", name: "TRN changed for #{@teacher_name}")
    ).to be_visible
    expect(
      page.get_by_text("The old TRN has been deleted from the record.")
    ).to be_visible
    expect(page.get_by_text(@old_trn, exact: true)).to be_visible
    expect(page.get_by_text(@new_trn, exact: true)).to be_visible

    expect(@teacher.reload).to have_attributes(
      trn: @new_trn,
      trs_response: "ok",
      trs_redirected_to: nil
    )
    expect(school_period.reload.teacher_id).to eq(@teacher.id)

    page.get_by_role("link", name: "Back to teachers", exact: true).click
    expect(page).to have_url(admin_teachers_path)

    page.goto(admin_teacher_path(@teacher))
    expect(
      page.get_by_role("link", name: "Change the TRN for this deactivated record")
    ).not_to be_visible

    page.get_by_role("link", name: "Timeline", exact: true).click
    expect(
      page.get_by_text(
        "TRN changed from '#{@old_trn}' to '#{@new_trn}'",
        exact: true
      )
    ).to be_visible
  end

  it "shows validation errors for an invalid TRN and unchecked confirmation" do
    when_i_start_the_change_trn_journey

    page.get_by_role("button", name: "Continue", exact: true).click

    expect(
      page.get_by_role(
        "link",
        name: "Teacher reference number must include at least 5 digits",
        exact: true
      )
    ).to be_visible

    page.get_by_label("Enter the new TRN", exact: true).fill("1234")
    page.get_by_role("button", name: "Continue", exact: true).click

    expect(
      page.get_by_role(
        "link",
        name: "Teacher reference number must include at least 5 digits",
        exact: true
      )
    ).to be_visible

    when_i_enter_the_replacement_trn
    page.get_by_role("button", name: "Confirm", exact: true).click

    expect(
      page.get_by_role(
        "link",
        name: "Confirm you want to change this teacher’s TRN",
        exact: true
      )
    ).to be_visible

    then_the_teacher_is_unchanged
  end

  %i[entry confirmation].each do |step|
    it "allows cancellation from the #{step} page without changing the teacher" do
      when_i_start_the_change_trn_journey
      when_i_enter_the_replacement_trn if step == :confirmation

      page.get_by_role(
        "link",
        name: "Cancel and go back to #{@teacher_name}",
        exact: true
      ).click

      expect(page).to have_url(admin_teacher_path(@teacher))
      then_the_teacher_is_unchanged
    end
  end

private

  def when_i_start_the_change_trn_journey
    page.goto(admin_teacher_path(@teacher))
    page.get_by_role(
      "link",
      name: "Change the TRN for this deactivated record",
      exact: true
    ).click

    expect(
      page.get_by_role("heading", name: "Change TRN for deactivated record")
    ).to be_visible
  end

  def when_i_enter_the_replacement_trn
    page.get_by_label("Enter the new TRN", exact: true).fill(@new_trn)
    page.get_by_role("button", name: "Continue", exact: true).click

    expect(
      page.get_by_role(
        "heading",
        name: "Confirm change of TRN for #{@teacher_name}"
      )
    ).to be_visible
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
end
