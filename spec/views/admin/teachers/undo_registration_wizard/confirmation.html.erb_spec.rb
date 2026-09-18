RSpec.describe "admin/teachers/undo_registration_wizard/confirmation.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:undo_action) { "close" }
  let(:wizard) do
    Admin::Teachers::UndoRegistrationWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :confirmation
    )
  end

  before do
    store.undo_action = undo_action
    assign(:teacher, teacher)
    assign(:wizard, wizard)
    render
  end

  it "displays the confirmation page" do
    expect(view.content_for(:page_title)).to eq("Registration undone")
    expect(rendered).to have_text("Registration undone")
    expect(rendered).to have_text("Associated school, training, and mentorship periods have been closed.")
    expect(rendered).to have_text("What you need to do")
    expect(rendered).to have_text("If training was delivered by a lead provider, tell them that you’ve undone this registration. They’ll need to update their own records.")
  end

  it "links back to teachers" do
    expect(rendered).to have_link("Back to teachers", href: admin_teachers_path)
  end

  context "when the registration was deleted" do
    let(:undo_action) { "delete" }

    it "uses delete wording" do
      expect(rendered).to have_text("Associated school, training, and mentorship periods have been deleted.")
    end
  end
end
