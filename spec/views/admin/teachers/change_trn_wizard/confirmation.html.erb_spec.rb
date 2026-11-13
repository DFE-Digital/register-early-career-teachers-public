RSpec.describe "admin/teachers/change_trn_wizard/confirmation.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs, trn: "7654321") }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    Admin::Teachers::ChangeTRNWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :confirmation
    )
  end

  before do
    store.old_trn = "7654321"
    store.trn = "2345678"

    assign(:teacher, teacher)
    assign(:wizard, wizard)
  end

  context "when replacement was completed" do
    before do
      store.records_processed = "replaced"
      render
    end

    it "shows replacement confirmation content" do
      expect(view.content_for(:page_title)).to eq("TRN changed for #{wizard.teacher_name}")
      expect(rendered).to have_text("TRN changed for #{wizard.teacher_name}")
      expect(rendered).to have_text("TRN 7654321")
      expect(rendered).to have_text("updated to 2345678")
      expect(rendered).to have_text("The old TRN has been deleted from the record.")
      expect(rendered).to have_link("Back to teachers", href: admin_teachers_path)
    end
  end

  context "when records were merged" do
    before do
      store.records_processed = "merged"
      store.source_teacher_name = "Sarah Smith"
      render
    end

    it "shows merge confirmation content" do
      expect(view.content_for(:page_title)).to eq("Records merged for Sarah Smith")
      expect(rendered).to have_text("Records merged for Sarah Smith")
      expect(rendered).to have_text("The record with the TRN 7654321")
      expect(rendered).to have_text("has been merged into the record with the TRN")
      expect(rendered).to have_text("2345678")
      expect(rendered).to have_text("What you need to do now")
      expect(rendered).to have_link("Back to teachers", href: admin_teachers_path)
    end
  end
end
