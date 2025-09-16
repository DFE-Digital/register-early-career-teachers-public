RSpec.describe Schools::Mentors::ECTMentorTrainingDetailsComponent, type: :component do
  include TeacherHelper

  let(:school) { FactoryBot.create(:school) }
  let(:mentor_start_date) { Date.new(2023, 1, 1) }
  let(:teacher) { FactoryBot.create(:teacher, mentor_became_ineligible_for_funding_on: nil) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: mentor_start_date, finished_on: nil) }

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Hidden leaf village") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

  context "when teacher is eligible and there is a provider-led ECT with a lead provider" do
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:ect_start_date) { mentor_start_date + 1.month }
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: ect_teacher,
                        school:,
                        started_on: ect_start_date,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: ect_start_date, finished_on: nil)
      FactoryBot.create(:training_period, :ongoing, :provider_led, :for_mentor, mentor_at_school_period: mentor, school_partnership:, started_on: ect_start_date, finished_on: nil)
    end

    it "shows the lead provider name from the mentor’s provider-led training period" do
      render_inline(described_class.new(teacher:, mentor:))
      expect(rendered_content).to have_text("Hidden leaf village")
    end
  end

  context "when teacher is ineligible because they completed training" do
    let(:date) { Date.new(2024, 1, 1) }
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:ect_start_date) { mentor_start_date + 1.month }
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: ect_teacher,
                        school:,
                        started_on: ect_start_date,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: ect_start_date, finished_on: nil)
      FactoryBot.create(:training_period, :ongoing, :provider_led, school_partnership:, ect_at_school_period: ect)

      teacher.update!(
        mentor_became_ineligible_for_funding_on: date,
        mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
      )
    end

    it "shows completed copy with GOV.UK date and hides the cards" do
      render_inline(described_class.new(teacher:, mentor:))

      expect(rendered_content).to have_css(
        ".govuk-body",
        text: "#{teacher_full_name(teacher)} completed mentor training on #{date.to_fs(:govuk)}."
      )
      expect(rendered_content).not_to have_text("Reported to us by your school")
      expect(rendered_content).not_to have_text("Reported to us by your lead provider")
    end
  end

  context "when teacher is ineligible because they started but did not complete" do
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:ect_start_date) { mentor_start_date + 1.month }
    let(:ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: ect_teacher,
                        school:,
                        started_on: ect_start_date,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: ect_start_date, finished_on: nil)

      teacher.update!(
        mentor_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
        mentor_became_ineligible_for_funding_reason: "started_not_completed"
      )
    end

    it "shows the started-not-completed paragraph and hides the cards" do
      render_inline(described_class.new(teacher:, mentor:))

      expect(rendered_content).to have_css(".govuk-body", text: /cannot do further mentor training/i)
      expect(rendered_content).to have_text("lead provider")
      expect(rendered_content).not_to have_text("Reported to us by your school")
      expect(rendered_content).not_to have_text("Reported to us by your lead provider")
    end
  end

  context "when all ECTs are school-led" do
    let(:ect_teacher) { FactoryBot.create(:teacher) }
    let(:school_led_ect) do
      FactoryBot.create(:ect_at_school_period,
                        teacher: ect_teacher,
                        school:,
                        started_on: mentor_start_date + 1.month,
                        finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: school_led_ect, started_on: school_led_ect.started_on, finished_on: nil)
      FactoryBot.create(:training_period, :ongoing, :school_led, ect_at_school_period: school_led_ect)
    end

    it "does not render" do
      component = described_class.new(teacher:, mentor:)
      expect(component.render?).to be false
      render_inline(component)
      expect(rendered_content).to be_empty
    end
  end

  context "when no ECTs are assigned" do
    it "does not render" do
      component = described_class.new(teacher:, mentor:)

      expect(component.render?).to be(false)

      result = render_inline(component)
      expect(result.to_html.strip).to eq("")
    end
  end
end
