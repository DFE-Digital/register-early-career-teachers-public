RSpec.describe Admin::Teachers::UndoRegistrationWizard::MentorshipPeriodsSummaryComponent, type: :component do
  subject(:rendered) do
    render_inline(
      described_class.new(
        mentorship_periods: [mentorship_period],
        school_period:,
        end_date_for:
      )
    )
  end

  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.new(2025, 9, 1) }
  let(:end_date) { Date.new(2026, 9, 18) }
  let(:end_date_for) { ->(_mentorship_period) { end_date } }

  context "with an ECT school period" do
    let(:school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:mentor) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: school_period,
        mentor:,
        started_on:
      )
    end
    let(:mentor_name) { Teachers::Name.new(mentor.teacher).full_name }

    it "shows the table headers" do
      expect(rendered).to have_css("thead th", text: "Name")
      expect(rendered).to have_css("thead th", text: "Start date")
      expect(rendered).to have_css("thead th", text: "End date")
    end

    it "shows the mentorship period" do
      table_row = rendered.css("tbody tr").first
      row_values = table_row.css("th, td").map(&:text)

      expect(row_values).to eq([
        mentor_name,
        started_on.to_fs(:govuk),
        end_date.to_fs(:govuk)
      ])
    end

    it "uses the teacher name as the row header" do
      expect(rendered).to have_css("tbody th[scope='row']", text: mentor_name)
    end
  end

  context "with a mentor school period" do
    let(:school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:mentee) do
      FactoryBot.create(
        :ect_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee:,
        mentor: school_period,
        started_on:
      )
    end
    let(:mentee_name) { Teachers::Name.new(mentee.teacher).full_name }

    it "shows the mentorship period" do
      table_row = rendered.css("tbody tr").first
      row_values = table_row.css("th, td").map(&:text)

      expect(row_values).to eq([
        mentee_name,
        started_on.to_fs(:govuk),
        end_date.to_fs(:govuk)
      ])
    end
  end

  context "without an end date" do
    let(:school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:mentor) do
      FactoryBot.create(
        :mentor_at_school_period,
        :unfinished,
        school:,
        started_on:
      )
    end
    let(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :unfinished,
        mentee: school_period,
        mentor:,
        started_on:
      )
    end
    let(:end_date_for) { ->(_mentorship_period) {} }

    it "shows the period as present" do
      expect(rendered).to have_css("td", text: "Present")
    end
  end

  context "with an unexpected school period" do
    let(:school_period) { double("school period") }

    it "raises when an unexpected period type is supplied" do
      component = described_class.new(mentorship_periods: [], school_period:, end_date_for:)

      expect { component.send(:related_teacher, double("mentorship period")) }
        .to raise_error(described_class::UnexpectedSchoolPeriodError)
    end
  end
end
