RSpec.describe "admin/teachers/undo_registration_wizard/start.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    Admin::Teachers::UndoRegistrationWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :start
    )
  end

  before do
    assign(:teacher, teacher)
    assign(:wizard, wizard)
    render
  end

  it "displays the start page" do
    expect(view.content_for(:page_title)).to eq("Undo a registration and update school periods for #{wizard.teacher_name}")
    expect(rendered)
      .to have_text("Undo a registration for #{wizard.teacher_name} and update the related school periods")
    expect(rendered).to have_text("Only continue if the registration was made in error.")
  end

  it "has a Continue link" do
    expect(rendered).to have_link("Continue", href: wizard.next_step_path)
  end

  it "links back to the teachers school history" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_teacher_school_path(teacher))
  end

  it "links back to the teacher overview when cancelling" do
    expect(rendered)
      .to have_link(
        "Cancel and go back to #{wizard.teacher_name}",
        href: admin_teacher_path(teacher)
      )
  end
end
