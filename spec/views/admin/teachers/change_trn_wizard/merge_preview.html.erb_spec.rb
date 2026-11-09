RSpec.describe "admin/teachers/change_trn_wizard/merge_preview.html.erb" do
  let(:teacher) do
    FactoryBot.create(:teacher, :deactivated_in_trs, trn: "7654321")
  end
  let(:destination) do
    FactoryBot.create(
      :teacher,
      trn: "2345678",
      trs_response: "ok",
      trs_first_name: "Sarah",
      trs_last_name: "Jones"
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    Admin::Teachers::ChangeTRNWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :merge_preview
    )
  end

  before do
    store.trn = destination.trn
    store.destination_teacher_id = destination.id

    assign(:teacher, teacher)
    assign(:wizard, wizard)

    render
  end

  it "shows merge preview content for source and destination records" do
    expect(view.content_for(:page_title)).to eq("Check teacher records before merging")
    expect(rendered).to have_text("Deactivated record")
    expect(rendered).to have_text("Active record being merged with")
    expect(rendered).to have_text(Teachers::Name.new(teacher).full_name)
    expect(rendered).to have_text(Teachers::Name.new(destination).full_name)
    expect(rendered).to have_text(teacher.trn)
    expect(rendered).to have_text(destination.trn)
    expect(rendered).to have_button("Continue")
  end
end
