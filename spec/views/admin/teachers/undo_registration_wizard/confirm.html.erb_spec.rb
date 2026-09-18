RSpec.describe "admin/teachers/undo_registration_wizard/confirm.html.erb" do
  let(:today) { Date.new(2026, 9, 18) }
  let(:teacher) do
    FactoryBot.create(
      :teacher,
      trs_first_name: "Kyojuro",
      trs_last_name: "Rengoku"
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:) }
  let(:wizard) do
    Admin::Teachers::UndoRegistrationWizard::Wizard.new(
      store:,
      teacher_id: teacher.id,
      current_step: :confirm
    )
  end

  around do |example|
    travel_to(today) { example.run }
  end

  before do
    assign(:teacher, teacher)
    assign(:wizard, wizard)
  end

  context "when the teacher has an ECT school period with a billable declaration" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :unfinished,
        ect_at_school_period: at_school_period
      )
    end

    let!(:declaration) do
      FactoryBot.create(:declaration, :eligible, training_period:)
    end

    let(:mentor) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        school: at_school_period.school,
        started_on: at_school_period.started_on
      )
    end

    let!(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: at_school_period,
        mentor:
      )
    end

    before { render }

    it "uses close wording" do
      expect(view.content_for(:page_title))
        .to eq("Confirm undo registration and close school periods for Kyojuro Rengoku")
      expect(rendered).to have_text("The periods shown below will be closed with the end dates shown.")
    end

    it "shows the periods that will be closed" do
      expect(rendered).to have_css("h3", text: "School period that will be closed", normalize_ws: true)
      expect(rendered).to have_css("h3", text: "ECT training period that will be closed", normalize_ws: true)
      expect(rendered).to have_css("h3", text: "Mentorship period that will be closed", normalize_ws: true)
    end

    it "asks the admin to confirm closing the periods" do
      expect(rendered).to have_field(
        "I confirm I want to undo this registration and close these school and training periods",
        type: "checkbox"
      )
    end

    it "includes the reviewed period IDs" do
      expect(rendered).to have_field("confirm_expected_training_period_ids", type: "hidden", with: training_period.id.to_s)
      expect(rendered).to have_field("confirm_expected_mentorship_period_ids", type: "hidden", with: mentorship_period.id.to_s)
    end

    context "when affected periods start in the future" do
      let(:training_start_date) { 1.week.from_now.to_date }
      let(:mentorship_start_date) { 2.weeks.from_now.to_date }
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :unfinished,
          ect_at_school_period: at_school_period,
          started_on: training_start_date
        )
      end
      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          :unfinished,
          mentee: at_school_period,
          mentor:,
          started_on: mentorship_start_date
        )
      end

      it "shows the projected end date for each period" do
        rendered_page = Capybara.string(rendered)
        school_period_card = rendered_page.find(".govuk-summary-card", text: at_school_period.school.name)
        training_period_card = rendered_page.find(".govuk-summary-card", text: training_period.lead_provider_name)
        mentorship_end_date = rendered_page.find("tbody tr td:last-child").text

        expect(school_period_card).to have_summary_list_row("End date", value: today.to_fs(:govuk))
        expect(training_period_card).to have_summary_list_row("End date", value: training_start_date.to_fs(:govuk))
        expect(mentorship_end_date).to eq(mentorship_start_date.to_fs(:govuk))
      end
    end
  end

  context "when the teacher has an ECT school period without declarations" do
    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :school_led,
        :unfinished,
        ect_at_school_period: at_school_period
      )
    end

    before { render }

    it "uses delete wording" do
      expect(view.content_for(:page_title))
        .to eq("Confirm undo registration and delete school periods for Kyojuro Rengoku")
    end

    it "shows the periods that will be deleted" do
      expect(rendered).to have_css("h3", text: "School period that will be deleted", normalize_ws: true)
      expect(rendered).to have_css("h3", text: "ECT training period that will be deleted", normalize_ws: true)
    end

    it "shows the affected training period" do
      expect(rendered).to have_text("School-led training programme")
    end

    it "asks the admin to confirm deleting the periods" do
      expect(rendered).to have_field(
        "I confirm I want to undo this registration and delete these school and training periods",
        type: "checkbox"
      )
    end
  end

  context "when the teacher has a mentor school period" do
    let(:at_school_period) do
      FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:)
    end

    let(:mentee) do
      FactoryBot.create(
        :ect_at_school_period,
        :unfinished,
        school: at_school_period.school,
        started_on: at_school_period.started_on
      )
    end

    let!(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentor: at_school_period,
        mentee:
      )
    end

    before { render }

    it "shows the mentor period and associated ECT" do
      expect(rendered).to have_css("dd", exact_text: "Mentor")
      expect(rendered).to have_text(Teachers::Name.new(mentee.teacher).full_name)
    end
  end

  it "shows the destructive confirmation button" do
    render

    expect(rendered).to have_button("Confirm")
    expect(rendered).to have_text("This action cannot be undone.")
  end

  it "links back to the previous step" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: wizard.previous_step_path)
  end

  it "links to the teacher overview when cancelling" do
    render

    expect(rendered).to have_link("Cancel and go back to Kyojuro Rengoku", href: admin_teacher_path(teacher))
  end
end
