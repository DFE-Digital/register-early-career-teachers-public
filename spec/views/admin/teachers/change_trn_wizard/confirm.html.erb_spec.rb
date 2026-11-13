RSpec.describe "admin/teachers/change_trn_wizard/confirm.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs, trn: "7654321") }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    Admin::Teachers::ChangeTRNWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :confirm
    )
  end

  before do
    assign(:teacher, teacher)
    assign(:wizard, wizard)
  end

  context "when confirming a replacement" do
    before do
      store.trn = "2345678"
      store.trs_first_name = "Sarah"
      store.trs_last_name = "Jones"
    end

    it "renders the replacement confirmation form" do
      render

      expect(view.content_for(:page_title)).to eq("Confirm change of TRN for #{wizard.teacher_name}")
      expect(rendered).to have_css(%(form[action="#{wizard.current_step_path}"]))
      expect(rendered).to have_field("confirm_expected_trn", type: "hidden", with: "2345678")
      expect(rendered).to have_field("I confirm I want to change this teacher’s TRN", type: "checkbox")
      expect(rendered).to have_text("Current TRN")
      expect(rendered).to have_text("New TRN")
      expect(rendered).to have_text("Name from TRS")
      expect(rendered).to have_text("Sarah Jones")
    end

    context "when the teacher has a corrected name" do
      before do
        teacher.update!(corrected_name: "Sarah Smith")
      end

      it "uses the corrected name in the heading" do
        render

        expect(view.content_for(:page_title)).to eq("Confirm change of TRN for Sarah Smith")
      end
    end
  end

  context "when confirming a merge" do
    let!(:destination) do
      FactoryBot.create(:teacher, trn: "2345678", trs_response: "ok")
    end

    before do
      store.trn = destination.trn
      store.destination_teacher_id = destination.id
      render
    end

    it "renders the merge confirmation form" do
      expect(view.content_for(:page_title)).to eq("Confirm merge for #{wizard.teacher_name}")
      expect(rendered).to have_css(%(form[action="#{wizard.current_step_path}"]))
      expect(rendered).to have_field("confirm_expected_trn", type: "hidden", with: destination.trn)
      expect(rendered).to have_field("I confirm I want to merge these teacher records", type: "checkbox")
      expect(rendered).to have_text("Deactivated TRN")
      expect(rendered).to have_text("Active TRN being merged with")
      expect(rendered).to have_text(teacher.trn)
      expect(rendered).to have_text(destination.trn)
    end
  end
end
