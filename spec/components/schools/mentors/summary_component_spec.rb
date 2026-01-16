RSpec.describe Schools::Mentors::SummaryComponent, type: :component do
  include Rails.application.routes.url_helpers

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

  context "with no ECTs" do
    it "shows No ECTs assigned" do
      render_inline(described_class.new(mentor:, school:))
      expect(rendered_content).to have_css(".govuk-summary-list__row", text: "Assigned ECTs")
      expect(rendered_content).to have_css(".govuk-summary-list__value", text: "No ECTs assigned")
    end
  end

  context "with less than or equal to 5 current ECTs" do
    let(:current_teacher) { ect1_teacher }
    let(:upcoming_teacher) { ect2_teacher }
    let(:finished_teacher) { ect3_teacher }

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

    let!(:ects) do
      FactoryBot.create_list(:teacher, 3).map do |ect_teacher|
        ect = FactoryBot.create(:ect_at_school_period, teacher: ect_teacher, school:, started_on:, finished_on: nil)
        FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect, started_on:, finished_on: nil)
        ect_teacher
      end
    end

    before do
      FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: current_period, started_on: current, finished_on: nil)
      FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: upcoming_period, started_on: upcoming, finished_on: nil)
      FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: finished_period, started_on: finished, finished_on: Date.yesterday)
    end

    it "lists upto 5 current ECT names" do
      render_inline(described_class.new(mentor:, school:))

      expect(rendered_content).not_to have_css(".govuk-summary-list__value", text: "No ECTs assigned")

      expect(rendered_content).to have_css(".govuk-summary-list__value", text: full_name(current_teacher))
      expect(rendered_content).to have_css(".govuk-summary-list__value", text: full_name(upcoming_teacher))
      expect(rendered_content).not_to have_css(".govuk-summary-list__value", text: full_name(finished_teacher))

      ects.each do |teacher|
        expect(rendered_content).to have_css(".govuk-summary-list__value", text: full_name(teacher))
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

    it "shows ECT count instead of listing names" do
      render_inline(described_class.new(mentor:, school:))
      expect(rendered_content).to have_css(".govuk-summary-list__value", text: "6 assigned ECTs")
    end
  end

  context "when there are multiple mentors" do
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
      render_inline(described_class.new(mentor:, school:))
      expect(rendered_content).to have_css(".govuk-summary-list__value", text: full_name(ect1_teacher))
      expect(rendered_content).not_to have_css(".govuk-summary-list__value", text: full_name(ect2_teacher))
    end
  end
end

def full_name(teacher)
  "#{teacher.trs_first_name} #{teacher.trs_last_name}"
end
