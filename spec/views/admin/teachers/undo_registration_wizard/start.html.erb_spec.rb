RSpec.describe "admin/teachers/undo_registration_wizard/start.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:store) { FactoryBot.build(:session_repository) }
  let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:) }
  let!(:declaration) { nil }
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
    expect(view.content_for(:page_title)).to eq("Undo a registration and delete school periods for #{wizard.teacher_name}")
    expect(rendered).to have_text(
      "Undo a registration for #{wizard.teacher_name} and delete the related school periods",
      normalize_ws: true
    )
    expect(rendered).to have_text("Only continue if the registration was made in error.")
  end

  context "when the registration has a billable declaration" do
    let(:training_period) do
      FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
    end
    let(:declaration) { FactoryBot.create(:declaration, :eligible, training_period:) }

    it "uses close wording" do
      expect(view.content_for(:page_title)).to eq("Undo a registration and close school periods for #{wizard.teacher_name}")
      expect(rendered).to have_text(
        "Undo a registration for #{wizard.teacher_name} and close the related school periods",
        normalize_ws: true
      )
    end
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
