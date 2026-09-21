RSpec.describe "admin/teachers/undo_registration_wizard/select_school_period.html.erb" do
  let(:teacher) do
    FactoryBot.create(
      :teacher,
      trs_first_name: "Son",
      trs_last_name: "Goku"
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    Admin::Teachers::UndoRegistrationWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :select_school_period
    )
  end
  let(:appropriate_body) { FactoryBot.create(:appropriate_body_period) }
  let!(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      school_reported_appropriate_body: appropriate_body,
      started_on: Date.new(2024, 9, 25),
      finished_on: nil
    )
  end
  let!(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher:,
      started_on: Date.new(2023, 9, 25),
      finished_on: Date.new(2024, 9, 24)
    )
  end

  before do
    assign(:teacher, teacher)
    assign(:wizard, wizard)
    render
  end

  it "displays the selection page" do
    expect(view.content_for(:page_title)).to eq("Select a school period to undo for Son Goku")
    expect(rendered).to have_text("Son Goku has more than one school period. Select the period to undo.")
  end

  it "shows the ECT school periods" do
    expect(rendered).to have_css("h2", text: "ECT school periods")
    expect(rendered).to have_field(
      ect_at_school_period.school.name,
      type: "radio",
      with: "ect:#{ect_at_school_period.id}"
    )
    expect(rendered).to have_text(appropriate_body.name)
    expect(rendered).to have_text("25 September 2024 to present")
  end

  it "shows the mentor school periods" do
    expect(rendered).to have_css("h2", text: "Mentor school periods")
    expect(rendered).to have_field(
      mentor_at_school_period.school.name,
      type: "radio",
      with: "mentor:#{mentor_at_school_period.id}"
    )
    expect(rendered).to have_text("25 September 2023 to 24 September 2024")
  end

  context "when the teacher has no ECT school periods" do
    let!(:ect_at_school_period) { nil }

    it "does not show the ECT school periods heading" do
      expect(rendered).not_to have_css("h2", text: "ECT school periods")
    end
  end

  context "when the teacher has no mentor school periods" do
    let!(:mentor_at_school_period) { nil }

    it "does not show the mentor school periods heading" do
      expect(rendered).not_to have_css("h2", text: "Mentor school periods")
    end
  end

  it "has a Continue button" do
    expect(rendered).to have_button("Continue")
  end

  it "links back to the start step" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: wizard.previous_step_path)
  end

  it "links to the teacher overview when cancelling" do
    expect(rendered)
      .to have_link("Cancel and go back to Son Goku", href: admin_teacher_path(teacher))
  end
end
