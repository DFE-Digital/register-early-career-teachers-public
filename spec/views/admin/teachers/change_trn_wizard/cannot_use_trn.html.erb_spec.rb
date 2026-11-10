RSpec.describe "admin/teachers/change_trn_wizard/cannot_use_trn.html.erb" do
  let(:teacher) do
    FactoryBot.create(
      :teacher,
      :deactivated_in_trs,
      trs_first_name: "Bruce",
      trs_last_name: "Wayne"
    )
  end

  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    Admin::Teachers::ChangeTRNWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :cannot_use_trn
    )
  end

  before do
    assign(:teacher, teacher)
    assign(:wizard, wizard)
    render
  end

  it "tells the user they cannot use the TRN" do
    expect(view.content_for(:page_title)).to eq("You cannot use this TRN")
    expect(view.content_for(:page_header)).to have_css("h1", text: "You cannot use this TRN")
    expect(rendered).to have_text("Contact the development team.")
  end

  it "links back to the teacher" do
    expect(rendered).to have_link("Back to Bruce Wayne", href: admin_teacher_path(teacher))
  end

  it "has a back link to TRN entry" do
    expect(view.content_for(:backlink_or_breadcrumb))
      .to have_link("Back", href: admin_teacher_change_trn_wizard_enter_trn_path(teacher))
  end
end
