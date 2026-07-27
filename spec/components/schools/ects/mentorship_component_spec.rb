RSpec.describe Schools::ECTs::MentorshipComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(ect_at_school_period) }

  let(:mentee_teacher) do
    FactoryBot.create(:teacher, corrected_name: "Test Mentee")
  end
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      teacher: mentee_teacher,
      started_on: 1.year.ago
    )
  end

  context "when the ECT has no current mentorship" do
    context "and there are no available mentors" do
      it "renders warning text with a link to register a new mentor" do
        render_inline(component)

        expect(page).to have_css(".govuk-warning-text")
        expect(page).to have_link(
          "Assign a mentor for this ECT",
          href: schools_register_mentor_wizard_start_path(ect_id: ect_at_school_period.id)
        )
      end
    end

    context "and there are available mentors" do
      let!(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          :unfinished,
          school: ect_at_school_period.school,
          started_on: ect_at_school_period.started_on
        )
      end

      it "renders warning text with a link to the mentorships page" do
        render_inline(component)

        expect(page).to have_css(".govuk-warning-text")
        expect(page).to have_link(
          "Assign a mentor for this ECT",
          href: new_schools_ect_mentorship_path(ect_at_school_period)
        )
      end
    end
  end

  context "when the ECT has a current mentorship and no upcoming mentorships" do
    let(:current_mentor_teacher) do
      FactoryBot.create(:teacher, corrected_name: "Test Mentor")
    end
    let(:current_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: current_mentor_teacher,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:current_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: ect_at_school_period,
        mentor: current_mentor_at_school_period,
        started_on: current_mentor_at_school_period.started_on
      )
    end

    it "renders the current mentor name" do
      render_inline(component)

      expect(page).to have_text("Test Mentor")
      expect(page).not_to have_css("ul")
    end
  end

  context "when the ECT has a current mentorship that starts in the future" do
    let(:current_mentor_teacher) do
      FactoryBot.create(:teacher, corrected_name: "Test Mentor")
    end
    let(:current_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: current_mentor_teacher,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:current_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: ect_at_school_period,
        mentor: current_mentor_at_school_period,
        started_on: 1.week.from_now
      )
    end

    it "only renders the current mentor name" do
      render_inline(component)

      expect(page).to have_text("Test Mentor")
      expect(page).to have_no_css("ul")
    end
  end

  context "when the ECT has a current mentorship and an upcoming mentorship" do
    let(:current_mentor) do
      FactoryBot.create(:teacher, corrected_name: "Test Mentor")
    end
    let(:current_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: current_mentor,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:current_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        mentee: ect_at_school_period,
        mentor: current_mentor_at_school_period,
        started_on: current_mentor_at_school_period.started_on,
        finished_on: 1.month.from_now
      )
    end

    let(:future_mentor) do
      FactoryBot.create(:teacher, corrected_name: "Future Mentor")
    end
    let(:future_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: future_mentor,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:future_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: ect_at_school_period,
        mentor: future_mentor_at_school_period,
        started_on: current_mentorship_period.finished_on.next_day
      )
    end

    it "renders the current mentor name and upcoming mentorship details" do
      render_inline(component)

      expect(page).to have_text("Test Mentor")
      expect(page).to have_css("ul > li", count: 1)
      expect(page).to have_css(
        "ul > li",
        text: <<~TXT.squish
          Future Mentor (from
          #{future_mentorship_period.started_on.to_fs(:govuk)})
        TXT
      )
    end
  end

  context "when the ECT has a current mentorship and multiple upcoming mentorships" do
    let(:current_mentor) do
      FactoryBot.create(:teacher, corrected_name: "Test Mentor")
    end
    let(:current_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: current_mentor,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:current_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        mentee: ect_at_school_period,
        mentor: current_mentor_at_school_period,
        started_on: current_mentor_at_school_period.started_on,
        finished_on: 1.month.from_now
      )
    end

    let(:future_mentor) do
      FactoryBot.create(:teacher, corrected_name: "Future Mentor")
    end
    let(:future_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: future_mentor,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:future_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        mentee: ect_at_school_period,
        mentor: future_mentor_at_school_period,
        started_on: current_mentorship_period.finished_on.next_day,
        finished_on: 6.months.from_now
      )
    end

    let(:another_future_mentor) do
      FactoryBot.create(:teacher, corrected_name: "Another-future Mentor")
    end
    let(:another_future_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        teacher: another_future_mentor,
        school: ect_at_school_period.school,
        started_on: ect_at_school_period.started_on
      )
    end
    let!(:another_future_mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: ect_at_school_period,
        mentor: another_future_mentor_at_school_period,
        started_on: future_mentorship_period.finished_on.next_day
      )
    end

    it "renders the current mentor name and upcoming mentorship details" do
      render_inline(component)

      expect(page).to have_text("Test Mentor")
      expect(page).to have_css("ul > li", count: 2)
      expect(page).to have_css(
        "ul > li:nth-child(1)",
        text: <<~TXT.squish
          Future Mentor (from
          #{future_mentorship_period.started_on.to_fs(:govuk)})
        TXT
      )
      expect(page).to have_css(
        "ul > li:nth-child(2)",
        text: <<~TXT.squish
          Another-future Mentor (from
          #{another_future_mentorship_period.started_on.to_fs(:govuk)})
        TXT
      )
    end
  end
end
