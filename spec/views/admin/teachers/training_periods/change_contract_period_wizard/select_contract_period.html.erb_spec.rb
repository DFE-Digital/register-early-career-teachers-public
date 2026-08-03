RSpec.describe "admin/teachers/training_periods/change_contract_period_wizard/select_contract_period.html.erb" do
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished) }
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :unfinished,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on
    )
  end
  let(:teacher) { training_period.teacher }
  let(:store) { SessionRepository.new(session: {}, form_key: "change_contract_period") }
  let(:wizard) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      training_period_id: training_period.id,
      current_step: :select_contract_period
    )
  end

  before do
    assign(:teacher, teacher)
    assign(:wizard, wizard)
  end

  it "uses the fieldset legend as the page heading to avoid repeating the question for screen readers" do
    render

    expect(view.content_for(:page_header)).to be_blank
    expect(rendered).to have_css("legend h1", text: "Select new contract period for #{Teachers::Name.new(teacher).full_name}")
  end
end
