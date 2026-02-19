RSpec.describe Schools::TeacherProfileSummaryListComponent, type: :component do
  subject { page }

  let(:school) { FactoryBot.create(:school) }
  let(:mentee_teacher) { FactoryBot.create(:teacher, trn: "9876543", trs_first_name: "Kakarot", trs_last_name: "SSJ") }
  let(:mentor_teacher) { FactoryBot.create(:teacher, trn: "987654", trs_first_name: "Naruto", trs_last_name: "Ninetails") }
  let(:previous_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: 3.years.ago) }
  let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: mentor_teacher, started_on: 3.years.ago) }
  let(:mentee) do
    FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher: mentee_teacher, started_on: Date.new(2021, 9, 1),
                                                       email: "foobarect@madeup.com", working_pattern: "full_time")
  end

  context "when the ECT has a mentor assigned" do
    before do
      FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: previous_mentor, started_on: 3.years.ago, finished_on: 2.years.ago)
      FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: current_mentor, started_on: 2.years.ago)

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "renders the summary list container" do
      expect(page).to have_selector(".govuk-summary-list")
    end

    it { is_expected.to have_selector(".govuk-summary-list__row", count: 6) }
    it { is_expected.to have_summary_list_row("Name", value: "Kakarot SSJ") }
    it { is_expected.to have_summary_list_row("Email address", value: "foobarect@madeup.com") }
    it { is_expected.to have_summary_list_row("Mentor") }
    it { is_expected.to have_summary_list_row("School start date", value: "1 September 2021") }
    it { is_expected.to have_summary_list_row("Working pattern", value: "Full time") }
    it { is_expected.to have_summary_list_row("Status") }
  end

  context "when latest started training is deferred" do
    before do
      training_period = FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        deferred_at: Time.zone.today,
        deferral_reason: TrainingPeriod.deferral_reasons.keys.first
      )

      lead_provider = FactoryBot.create(:lead_provider, name: "Ambition Institute")

      active_lead_provider = FactoryBot.create(
        :active_lead_provider,
        lead_provider:,
        contract_period: training_period.schedule.contract_period
      )

      training_period.update!(
        school_partnership: nil,
        expression_of_interest: active_lead_provider
      )

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows training paused status" do
      expect(page).to have_text("Training paused")
      expect(page).to have_text("training is paused")
    end

    it "includes the lead provider name" do
      expect(page).to have_text("Ambition Institute")
    end
  end

  context "when training is withdrawn" do
    before do
      training_period = FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        withdrawn_at: Time.zone.today,
        withdrawal_reason: TrainingPeriod.withdrawal_reasons.keys.first
      )

      lead_provider = FactoryBot.create(:lead_provider, name: "Ambition Institute")

      active_lead_provider = FactoryBot.create(
        :active_lead_provider,
        lead_provider:,
        contract_period: training_period.schedule.contract_period
      )

      training_period.update!(
        school_partnership: nil,
        expression_of_interest: active_lead_provider
      )

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows action required status" do
      expect(page).to have_text("Action required")
      expect(page).to have_text(/no longer training with them/i)
    end

    it "includes the lead provider name" do
      expect(page).to have_text("Ambition Institute")
    end
  end

  context "when training is withdrawn and the ECT has no mentor assigned" do
    before do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        withdrawn_at: Time.zone.today,
        withdrawal_reason: TrainingPeriod.withdrawal_reasons.keys.first
      )

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows withdrawn status instead of mentor required" do
      expect(page).to have_text("Action required")
      expect(page).to have_text(/no longer training with them/i)

      expect(page).not_to have_text("Mentor required")
    end
  end

  context "when training is deferred and the ECT has no mentor assigned" do
    before do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        deferred_at: Time.zone.today,
        deferral_reason: TrainingPeriod.deferral_reasons.keys.first
      )

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows training paused instead of mentor required" do
      expect(page).to have_text("Training paused")
      expect(page).not_to have_text("Mentor required")
    end
  end

  context "when withdrawn but also reported as leaving" do
    before do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        withdrawn_at: Time.zone.today,
        withdrawal_reason: TrainingPeriod.withdrawal_reasons.keys.first
      )

      mentee.update!(finished_on: 1.day.from_now.to_date, reported_leaving_by_school_id: school.id)

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows leaving school instead of action required" do
      expect(page).to have_text("Leaving school")
      expect(page).not_to have_text("Action required")
    end
  end

  context "when deferred but also reported as leaving" do
    before do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        deferred_at: Time.zone.today,
        deferral_reason: TrainingPeriod.deferral_reasons.keys.first
      )

      mentee.update!(finished_on: 1.day.from_now.to_date, reported_leaving_by_school_id: school.id)

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows leaving school instead of training paused" do
      expect(page).to have_text("Leaving school")
      expect(page).not_to have_text("Training paused")
    end
  end

  context "when withdrawn but induction status is exempt" do
    before do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        withdrawn_at: Time.zone.today,
        withdrawal_reason: TrainingPeriod.withdrawal_reasons.keys.first
      )

      mentee_teacher.update!(trs_induction_status: "Exempt")

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows exempt status instead of action required" do
      expect(page).to have_text("Exempt")
      expect(page).not_to have_text("Action required")
    end
  end

  context "when deferred but induction status is exempt" do
    before do
      FactoryBot.create(
        :training_period,
        :provider_led,
        ect_at_school_period: mentee,
        started_on: mentee.started_on,
        deferred_at: Time.zone.today,
        deferral_reason: TrainingPeriod.deferral_reasons.keys.first
      )

      mentee_teacher.update!(trs_induction_status: "Exempt")

      render_inline(described_class.new(mentee, current_school: school))
    end

    it "shows exempt status instead of training paused" do
      expect(page).to have_text("Exempt")
      expect(page).not_to have_text("Training paused")
    end
  end
end
