RSpec.describe Schools::Mentors::DetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:school) { FactoryBot.create(:school) }
  let(:mentor_teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
  let(:current) { 1.week.ago }
  let(:upcoming) { 1.week.from_now }
  let(:finished) { 1.month.ago }
  let(:started_on) { 1.month.ago }

  let(:mentor) do
    FactoryBot.create(:mentor_at_school_period,
                      teacher: mentor_teacher,
                      school:,
                      started_on:,
                      finished_on: nil)
  end

  let(:current_teacher) { FactoryBot.create(:teacher, trs_first_name: "Konohamaru", trs_last_name: "Sarutobi") }
  let(:upcoming_teacher) { FactoryBot.create(:teacher, trs_first_name: "Boruto", trs_last_name: "Uzumaki") }
  let(:finished_teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
  let(:completed_teacher) { FactoryBot.create(:teacher, :induction_completed, trs_first_name: "Jiraiya", trs_last_name: "Sannin") }

  let(:current_period) do
    FactoryBot.create(:ect_at_school_period,
                      teacher: current_teacher,
                      school:,
                      started_on: current,
                      finished_on: nil)
  end

  let(:upcoming_period) do
    FactoryBot.create(:ect_at_school_period,
                      teacher: upcoming_teacher,
                      school:,
                      started_on: upcoming,
                      finished_on: nil)
  end

  let(:finished_period) do
    FactoryBot.create(:ect_at_school_period,
                      teacher: finished_teacher,
                      school:,
                      started_on: finished,
                      finished_on: Date.yesterday)
  end

  let(:completed_period) do
    FactoryBot.create(:ect_at_school_period,
                      teacher: completed_teacher,
                      school:,
                      started_on: finished,
                      finished_on: completed_teacher.trs_induction_completed_date)
  end

  context "when there are ECTs assigned to the mentor" do
    before do
      FactoryBot.create(:mentorship_period, mentor:, mentee: current_period, started_on: current, finished_on: nil)
      FactoryBot.create(:mentorship_period, mentor:, mentee: upcoming_period, started_on: upcoming, finished_on: nil)
      FactoryBot.create(:mentorship_period, mentor:, mentee: finished_period, started_on: finished, finished_on: Date.yesterday)
      FactoryBot.create(:mentorship_period, mentor:, mentee: completed_period, started_on: finished, finished_on: completed_teacher.trs_induction_completed_date)

      render_inline(described_class.new(teacher: mentor_teacher, mentor:))
    end

    it "renders the section heading" do
      expect(page).to have_css("h2.govuk-heading-m", text: "Mentor details")
    end

    it "shows the mentors name" do
      expect(page).to have_css(".govuk-summary-list__value", text: "Naruto Uzumaki")
    end

    it "shows the mentors email address" do
      expect(page).to have_css(".govuk-summary-list__value", text: mentor.email)
    end

    it "renders links for currently assigned ECTs" do
      expect(page).not_to have_css(".govuk-summary-list__value", text: "No ECTs assigned")

      expect(page).to have_link("Konohamaru Sarutobi", href: schools_ect_path(current_period, back_to_mentor: true, mentor_id: mentor.id))
      expect(page).to have_link("Boruto Uzumaki", href: schools_ect_path(upcoming_period, back_to_mentor: true, mentor_id: mentor.id))
      expect(page).not_to have_link("Kakashi Hatake", href: schools_ect_path(finished_period, back_to_mentor: true, mentor_id: mentor.id))
      expect(page).not_to have_link("Jiraiya Sannin", href: schools_ect_path(completed_period, back_to_mentor: true, mentor_id: mentor.id))
    end
  end

  context "when there are ECTs not assigned to this mentor" do
    let(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
    let(:other_mentor) do
      FactoryBot.create(:mentor_at_school_period, teacher: other_teacher, school:, started_on:, finished_on: nil)
    end
    let(:unrelated_ect_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sauske", trs_last_name: "Uchiha") }
    let(:unrelated_ect) do
      FactoryBot.create(:ect_at_school_period, teacher: unrelated_ect_teacher, school:, started_on:, finished_on: nil)
    end

    before do
      FactoryBot.create(:mentorship_period, mentor: other_mentor, mentee: unrelated_ect, started_on:, finished_on: nil)
      render_inline(described_class.new(teacher: mentor_teacher, mentor:))
    end

    it "does not render ECTs assigned to other mentors" do
      expect(page).not_to have_css(".govuk-summary-list__value", text: "Sauske Uchiha")
    end
  end

  context "when there are no ECTs assigned to the mentor" do
    before do
      render_inline(described_class.new(teacher: mentor_teacher, mentor:))
    end

    it "renders the no ECTS assigned text" do
      expect(page).to have_css(".govuk-summary-list__value", text: "No ECTs assigned")
    end
  end
end
