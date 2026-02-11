RSpec.describe Admin::Teachers::SchoolSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(school_period:)) }

  include Rails.application.routes.url_helpers

  describe "ECT at school period" do
    let(:school) { FactoryBot.create(:school) }
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Appropriate Body Name") }
    let(:school_period_attributes) do
      {
        school:,
        started_on: Date.new(2023, 1, 1),
        finished_on: nil,
        working_pattern: "full_time",
        school_reported_appropriate_body: appropriate_body,
        email: "ect@example.com"
      }
    end
    let(:school_period) { FactoryBot.create(:ect_at_school_period, **school_period_attributes) }

    context "card title" do
      it "links to the admin school overview" do
        expect(rendered).to have_link(school.name, href: admin_school_overview_path(school.urn))
      end
    end

    context "URN row" do
      it "shows the school URN" do
        expect(rendered).to have_css("dt", text: "School URN")
        expect(rendered).to have_css("dd", text: school.urn)
      end
    end

    context "School start date row" do
      it "shows the start date" do
        expect(rendered).to have_css("dt", text: "School start date")
        expect(rendered).to have_css("dd", text: school_period.started_on.to_fs(:govuk))
      end
    end

    context "School end date row" do
      it "falls back for a missing end date" do
        expect(rendered).to have_css("dt", text: "School end date")
        expect(rendered).to have_css("dd", text: "No end date recorded")
      end

      context "when an end date exists" do
        let(:school_period_attributes) { super().merge(finished_on: Date.new(2023, 6, 30)) }

        it "shows the formatted end date" do
          expect(rendered).to have_css("dt", text: "School end date")
          expect(rendered).to have_css("dd", text: Date.new(2023, 6, 30).to_fs(:govuk))
        end
      end
    end

    context "Email row" do
      it "shows the period email" do
        expect(rendered).to have_css("dt", text: "Email address")
        expect(rendered).to have_css("dd", text: "ect@example.com")
      end

      context "when no email is present" do
        let(:school_period_attributes) { super().merge(email: nil) }

        it "falls back to the placeholder text" do
          expect(rendered).to have_css("dt", text: "Email address")
          expect(rendered).to have_css("dd", text: "Not available")
        end
      end
    end

    context "Appropriate body row" do
      it "shows the school reported appropriate body" do
        expect(rendered).to have_css("dt", text: "Appropriate body")
        expect(rendered).to have_css("dd", text: "Appropriate Body Name")
      end

      context "when no appropriate body is recorded" do
        let(:appropriate_body) { nil }

        it "falls back to the placeholder text" do
          expect(rendered).to have_css("dt", text: "Appropriate body")
          expect(rendered).to have_css("dd", text: "No appropriate body recorded")
        end
      end
    end

    context "Mentor row" do
      let(:older_mentor_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: school_period.started_on) }
      let(:newer_mentor_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: school_period.started_on + 1.month) }

      it "appears as the last row" do
        expect(rendered).to have_css(".govuk-summary-list__row:last-child dt", text: "Mentor")
      end

      context "when mentors are assigned" do
        let!(:older_mentorship) do
          FactoryBot.create(
            :mentorship_period,
            mentee: school_period,
            mentor: older_mentor_period,
            started_on: school_period.started_on + 1.month,
            finished_on: school_period.started_on + 2.months
          )
        end

        let!(:newer_mentorship) do
          FactoryBot.create(
            :mentorship_period,
            mentee: school_period,
            mentor: newer_mentor_period,
            started_on: school_period.started_on + 3.months,
            finished_on: nil
          )
        end

        it "displays mentors in a table with name, start date, and end date columns" do
          expect(rendered).to have_css("table.govuk-table")
          expect(rendered).to have_css("th", text: "Name")
          expect(rendered).to have_css("th", text: "Start date")
          expect(rendered).to have_css("th", text: "End date")
        end

        it "lists mentors newest to oldest with links" do
          newer_name = Teachers::Name.new(newer_mentor_period.teacher).full_name
          older_name = Teachers::Name.new(older_mentor_period.teacher).full_name

          expect(rendered).to have_link(newer_name, href: admin_teacher_induction_path(newer_mentor_period.teacher))
          expect(rendered).to have_link(older_name, href: admin_teacher_induction_path(older_mentor_period.teacher))
          html = rendered.to_html
          expect(html.index(newer_name)).to be > html.index(older_name)
        end

        it "shows formatted start dates" do
          expect(rendered).to have_css("td", text: older_mentorship.started_on.to_fs(:govuk))
          expect(rendered).to have_css("td", text: newer_mentorship.started_on.to_fs(:govuk))
        end

        it "shows formatted end dates or 'Present' for ongoing mentorships" do
          expect(rendered).to have_css("td", text: older_mentorship.finished_on.to_fs(:govuk))
          expect(rendered).to have_css("td", text: "Present")
        end
      end

      context "when no mentors are assigned" do
        let(:older_mentor_period) { nil }
        let(:newer_mentor_period) { nil }

        it "shows the fallback text" do
          expect(rendered).to have_css("dt", text: "Mentor")
          expect(rendered).to have_css("dd", text: "None assigned")
        end
      end
    end

    context "Working pattern row" do
      it "shows the formatted working pattern" do
        expect(rendered).to have_css("dt", text: "Working pattern")
        expect(rendered).to have_css("dd", text: "Full-time")
      end

      context "when no working pattern is present" do
        let(:school_period_attributes) { super().merge(working_pattern: nil) }

        it "falls back to the placeholder text" do
          expect(rendered).to have_css("dt", text: "Working pattern")
          expect(rendered).to have_css("dd", text: "Not available")
        end
      end
    end
  end

  describe "Mentor at school period" do
    let(:school) { FactoryBot.create(:school) }
    let(:school_period_attributes) do
      {
        school:,
        started_on: Date.new(2023, 6, 1),
        finished_on: nil,
        email: nil
      }
    end
    let(:school_period) { FactoryBot.create(:mentor_at_school_period, **school_period_attributes) }
    let(:older_ect_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: school_period.started_on, finished_on: school_period.started_on + 6.months) }
    let(:newer_ect_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: school_period.started_on + 1.month, finished_on: nil) }

    context "card title" do
      it "links to the admin school overview" do
        expect(rendered).to have_link(school.name, href: admin_school_overview_path(school.urn))
      end
    end

    context "URN row" do
      it "shows the school URN" do
        expect(rendered).to have_css("dt", text: "School URN")
        expect(rendered).to have_css("dd", text: school.urn)
      end
    end

    context "School start date row" do
      it "shows the start date" do
        expect(rendered).to have_css("dt", text: "School start date")
        expect(rendered).to have_css("dd", text: school_period.started_on.to_fs(:govuk))
      end
    end

    context "School end date row" do
      it "falls back for a missing end date" do
        expect(rendered).to have_css("dt", text: "School end date")
        expect(rendered).to have_css("dd", text: "No end date recorded")
      end

      context "when an end date exists" do
        let(:school_period_attributes) { super().merge(finished_on: Date.new(2023, 9, 1)) }

        it "shows the formatted end date" do
          expect(rendered).to have_css("dt", text: "School end date")
          expect(rendered).to have_css("dd", text: Date.new(2023, 9, 1).to_fs(:govuk))
        end
      end
    end

    context "Email row" do
      it "falls back when no email is present" do
        expect(rendered).to have_css("dt", text: "Email address")
        expect(rendered).to have_css("dd", text: "Not available")
      end

      context "when an email is present" do
        let(:school_period_attributes) { super().merge(email: "mentor@example.com") }

        it "shows the email address" do
          expect(rendered).to have_css("dt", text: "Email address")
          expect(rendered).to have_css("dd", text: "mentor@example.com")
        end
      end
    end

    context "Assigned ECTs row" do
      context "when ECTs are assigned" do
        let!(:older_mentorship) do
          FactoryBot.create(
            :mentorship_period,
            mentor: school_period,
            mentee: older_ect_period,
            started_on: school_period.started_on + 1.month,
            finished_on: school_period.started_on + 2.months
          )
        end

        let!(:newer_mentorship) do
          FactoryBot.create(
            :mentorship_period,
            mentor: school_period,
            mentee: newer_ect_period,
            started_on: school_period.started_on + 2.months,
            finished_on: nil
          )
        end

        it "displays ECTs in a table with name, start date, and end date columns" do
          expect(rendered).to have_css("table.govuk-table")
          expect(rendered).to have_css("th", text: "Name")
          expect(rendered).to have_css("th", text: "Start date")
          expect(rendered).to have_css("th", text: "End date")
        end

        it "lists ECTs newest to oldest with links" do
          newer_name = Teachers::Name.new(newer_ect_period.teacher).full_name
          older_name = Teachers::Name.new(older_ect_period.teacher).full_name

          expect(rendered).to have_link(newer_name, href: admin_teacher_induction_path(newer_ect_period.teacher))
          expect(rendered).to have_link(older_name, href: admin_teacher_induction_path(older_ect_period.teacher))
          html = rendered.to_html
          expect(html.index(newer_name)).to be > html.index(older_name)
        end

        it "shows formatted start dates" do
          expect(rendered).to have_css("td", text: older_mentorship.started_on.to_fs(:govuk))
          expect(rendered).to have_css("td", text: newer_mentorship.started_on.to_fs(:govuk))
        end

        it "shows formatted end dates or 'Present' for ongoing mentorships" do
          expect(rendered).to have_css("td", text: older_mentorship.finished_on.to_fs(:govuk))
          expect(rendered).to have_css("td", text: "Present")
        end
      end

      context "when no ECTs are assigned" do
        let(:older_ect_period) { nil }
        let(:newer_ect_period) { nil }

        it "shows the fallback text" do
          expect(rendered).to have_css("dt", text: "Assigned ECTs")
          expect(rendered).to have_css("dd", text: "None assigned")
        end
      end
    end
  end

  describe "#rows" do
    let(:school_period) { double("school period") }

    it "raises when an unexpected period type is supplied" do
      expect { described_class.new(school_period:).send(:rows) }
        .to raise_error(described_class::UnexpectedSchoolPeriodError)
    end
  end
end
