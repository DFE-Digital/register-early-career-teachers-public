RSpec.describe Schools::Mentors::SummaryComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject do
    render_inline described_class.new(mentor:, school:)
    page
  end

  let(:school) { FactoryBot.create(:school) }
  let(:mentor) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }

  let(:current) { 1.week.ago }
  let(:upcoming) { 1.week.from_now }
  let(:finished) { 1.month.ago }
  let(:started_on) { 1.month.ago }

  let!(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, teacher: mentor, school:, started_on:, finished_on: nil)
  end

  let(:ect1_teacher) { FactoryBot.create(:teacher, trs_first_name: "Konohamaru", trs_last_name: "Sarutobi") }
  let(:ect2_teacher) { FactoryBot.create(:teacher, trs_first_name: "Boruto", trs_last_name: "Uzumaki") }
  let(:ect3_teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
  let(:ect4_teacher) { FactoryBot.create(:teacher, :induction_completed, trs_first_name: "Jiraiya", trs_last_name: "Sannin") }

  describe "assigned ECTs" do
    context "with no ECTs" do
      it { is_expected.to have_summary_list_row("Assigned ECTs", value: "No ECTs assigned") }
    end

    context "with ECTs in various states" do
      let(:current_teacher) { ect1_teacher }
      let(:upcoming_teacher) { ect2_teacher }
      let(:finished_teacher) { ect3_teacher }
      let(:completed_teacher) { ect4_teacher }

      let(:current_period) do
        FactoryBot.create(:ect_at_school_period, teacher: current_teacher, school:, started_on: current, finished_on: nil)
      end

      let(:upcoming_period) do
        FactoryBot.create(:ect_at_school_period, teacher: upcoming_teacher, school:, started_on: upcoming, finished_on: nil)
      end

      let(:finished_period) do
        FactoryBot.create(:ect_at_school_period, teacher: finished_teacher, school:, started_on: finished, finished_on: Date.yesterday)
      end

      let(:completed_period) do
        FactoryBot.create(:ect_at_school_period, teacher: completed_teacher, school:, started_on: finished, finished_on: completed_teacher.trs_induction_completed_date)
      end

      before do
        FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: current_period, started_on: current, finished_on: nil)
        FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: upcoming_period, started_on: upcoming, finished_on: nil)
        FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: finished_period, started_on: finished, finished_on: Date.yesterday)
        FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: completed_period, started_on: finished, finished_on: completed_teacher.trs_induction_completed_date)
      end

      it { is_expected.not_to have_text("No ECTs assigned") }
      it { is_expected.to have_link(full_name(current_teacher), href: schools_ect_path(current_period)) }
      it { is_expected.to have_link(full_name(upcoming_teacher), href: schools_ect_path(upcoming_period)) }
      it { is_expected.not_to have_link(full_name(finished_teacher), href: schools_ect_path(finished_period)) }
      it { is_expected.not_to have_link(full_name(completed_teacher), href: schools_ect_path(completed_period)) }
    end

    context "with 5 or fewer current ECTs" do
      let!(:ects) do
        FactoryBot.create_list(:teacher, 5).map do |ect_teacher|
          ect = FactoryBot.create(:ect_at_school_period, teacher: ect_teacher, school:, started_on:, finished_on: nil)
          FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect, started_on:, finished_on: nil)
          ect_teacher
        end
      end

      it { is_expected.not_to have_text("No ECTs assigned") }

      it "lists each ECT by name" do
        ects.each do |teacher|
          expect(subject).to have_link(full_name(teacher), href: schools_ect_path(teacher.ect_at_school_periods.first))
        end
      end
    end

    context "with more than 5 ECTs" do
      before do
        FactoryBot.create_list(:teacher, 6).each do |ect_teacher|
          ect = FactoryBot.create(:ect_at_school_period, teacher: ect_teacher, school:, started_on:, finished_on: nil)
          FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect, started_on:, finished_on: nil)
        end
      end

      it { is_expected.to have_css(".govuk-summary-list__value", text: "6 assigned ECTs") }
    end

    context "when there are multiple mentors at the same school" do
      let(:second_mentor) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }
      let!(:second_mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: second_mentor, school:, started_on:)
      end

      let(:ect1) { FactoryBot.create(:ect_at_school_period, teacher: ect1_teacher, school:, started_on:, finished_on: nil) }
      let(:ect2) { FactoryBot.create(:ect_at_school_period, teacher: ect2_teacher, school:, started_on:, finished_on: nil) }

      before do
        FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect1, started_on:, finished_on: nil)
        FactoryBot.create(:mentorship_period, mentor: second_mentor_at_school_period, mentee: ect2, started_on:, finished_on: nil)
      end

      it "only shows ECTs assigned to the specific mentor" do
        expect(subject).to have_summary_list_row("Assigned ECTs", value: full_name(ect1_teacher))
        expect(subject).not_to have_summary_list_row("Assigned ECTs", value: full_name(ect2_teacher))
      end
    end
  end

  describe "training details" do
    let(:active_text) { "#{full_name(mentor)} is registered for ECTE mentor training with:" }
    let(:deferred_text) { "have told us that #{full_name(mentor)}'s ECTE mentor training is paused. Contact them if you think this is an error." }
    let(:withdrawn_text) { "have told us that #{full_name(mentor)} is not registered for ECTE mentor training with them. Contact them if you think this is an error." }

    shared_examples "does not show training details" do
      it { is_expected.not_to have_text(active_text) }
      it { is_expected.not_to have_text(deferred_text) }
      it { is_expected.not_to have_text(withdrawn_text) }
      it { is_expected.not_to have_summary_list_row("Lead provider") }
    end

    context "when the mentor has no training periods" do
      include_examples "does not show training details"
    end

    context "when the mentor has a completion date" do
      before do
        mentor.update!(
          mentor_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
          mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
        )
      end

      include_examples "does not show training details"

      context "and there is also a current training period" do
        before do
          FactoryBot.create(:training_period, :ongoing, :provider_led, :for_mentor, mentor_at_school_period:)
        end

        include_examples "does not show training details"
      end
    end

    context "when the mentor has a current training period" do
      let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :for_mentor, mentor_at_school_period:, started_on: 1.week.ago, finished_on: nil) }
      let!(:old_training_period) { FactoryBot.create(:training_period, :provider_led, :for_mentor, mentor_at_school_period:, started_on:, finished_on: 2.weeks.ago) }

      it { is_expected.to have_text(active_text) }
      it { is_expected.to have_summary_list_row("Lead provider", value: "#{training_period.lead_provider_name}Confirmed by #{training_period.lead_provider_name}") }
      it { is_expected.to have_summary_list_row("Delivery partner", value: training_period.delivery_partner_name) }
    end

    context "when the latest training period is deferred" do
      let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :for_mentor, :deferred, mentor_at_school_period:, started_on: 1.week.ago) }
      let(:lead_provider_name) { training_period.school_partnership.lead_provider.name }

      it { is_expected.to have_text(deferred_text) }
      it { is_expected.not_to have_summary_list_row("Lead provider") }
      it { is_expected.not_to have_summary_list_row("Delivery partner") }
    end

    context "when the latest training period is withdrawn" do
      let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :for_mentor, :withdrawn, mentor_at_school_period:, started_on: 1.week.ago) }
      let(:lead_provider_name) { training_period.school_partnership.lead_provider.name }

      it { is_expected.to have_text(withdrawn_text) }
      it { is_expected.not_to have_summary_list_row("Lead provider") }
      it { is_expected.not_to have_summary_list_row("Delivery partner") }
    end

    context "when the latest training period has finished normally" do
      let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :for_mentor, mentor_at_school_period:, started_on:, finished_on: 2.weeks.ago) }

      include_examples "does not show training details"
    end
  end
end

def full_name(teacher)
  "#{teacher.trs_first_name} #{teacher.trs_last_name}"
end
