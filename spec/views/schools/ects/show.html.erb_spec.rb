RSpec.describe "schools/ects/show.html.erb" do
  subject do
    render
    Capybara.string(rendered)
  end

  let(:contract_period) { FactoryBot.create(:contract_period) }
  let!(:current_ect_period) do
    FactoryBot.create(:ect_at_school_period,
                      :teaching_school_hub_ab,
                      teacher:,
                      started_on: "2025-01-11",
                      finished_on: nil,
                      school_reported_appropriate_body: requested_appropriate_body,
                      school: current_school,
                      working_pattern: "full_time",
                      email: "love@whale.com")
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition institute") }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school: current_ect_period.school) }
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Alpha Teaching School Hub") }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Barry", trs_last_name: "White", corrected_name: "Baz White") }
  let(:previous_school) { FactoryBot.create(:school, urn: "123456") }
  let(:current_school) { FactoryBot.create(:school, :state_funded, urn: "987654") }
  let(:requested_appropriate_body) { FactoryBot.create(:appropriate_body_period, name: "Requested AB") }
  let(:training_programme) { "provider_led" }
  let!(:training_period) { FactoryBot.create(:training_period, :provider_led, ect_at_school_period: current_ect_period, school_partnership:, started_on: "2025-01-11", finished_on: nil, training_programme:) }

  before do
    FactoryBot.create(:ect_at_school_period, :state_funded_school,
                      teacher:,
                      started_on: "2024-01-11",
                      finished_on: "2025-01-11",
                      school: previous_school,
                      email: "previous-address@whale.com")
    assign(:ect_at_school_period, current_ect_period)
    assign(:training_period, training_period)
    assign(:teacher, teacher)
  end

  describe "page_data" do
    before { render }

    it "has title" do
      expect(view.content_for(:page_title)).to eql("Baz White")
    end

    it "includes a back button that links to the school home page" do
      expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: schools_ects_home_path)
    end
  end

  describe "ECT details" do
    it "title" do
      expect(subject).to have_css("h2.govuk-heading-m", text: "ECT details")
    end

    it "full name" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Name")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: "Baz White")
    end

    it "current email address" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Email address")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: "love@whale.com")
    end

    describe "mentor" do
      context "when assigned" do
        let(:mentor) do
          FactoryBot.create(:teacher, trs_first_name: "Moby", trs_last_name: "Dick")
        end
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: current_ect_period.started_on,
            school: current_school,
            teacher: mentor
          )
        end
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            started_on: mentor_at_school_period.started_on,
            mentee: current_ect_period,
            mentor: mentor_at_school_period
          )
        end

        it "has mentor's full name" do
          expect(subject).to have_summary_list_row("Mentor", value: "Moby Dick")
        end
      end

      context "when current and future mentors are assigned" do
        let(:current_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "Moby", trs_last_name: "Dick")
        end
        let(:current_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: current_ect_period.started_on,
            school: current_school,
            teacher: current_mentor
          )
        end
        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            started_on: current_mentor_at_school_period.started_on,
            finished_on: 1.month.from_now,
            mentee: current_ect_period,
            mentor: current_mentor_at_school_period
          )
        end

        let(:future_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "John", trs_last_name: "Smith")
        end
        let(:future_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: current_ect_period.started_on,
            school: current_school,
            teacher: future_mentor
          )
        end
        let!(:future_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            started_on: current_mentorship_period.finished_on.next_day,
            mentee: current_ect_period,
            mentor: future_mentor_at_school_period
          )
        end

        it "has current mentor's full name" do
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "Moby Dick",
            matcher: [:has_text?, { exact: false }]
          )
        end

        it "displays upcoming mentorship details" do
          upcoming_mentorship_detail = <<~TXT.squish
            John Smith (from #{future_mentorship_period.started_on.to_fs(:govuk)})
          TXT
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "ul > li",
            matcher: [:has_css?, { count: 1 }]
          )
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "ul > li:nth-child(1)",
            matcher: [:has_css?, { text: upcoming_mentorship_detail }]
          )
        end
      end

      context "when current and multiple future mentors are assigned" do
        let(:current_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "Moby", trs_last_name: "Dick")
        end
        let(:current_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: current_ect_period.started_on,
            school: current_school,
            teacher: current_mentor
          )
        end
        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            started_on: current_mentor_at_school_period.started_on,
            finished_on: 1.month.from_now,
            mentee: current_ect_period,
            mentor: current_mentor_at_school_period
          )
        end

        let(:future_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "John", trs_last_name: "Smith")
        end
        let(:future_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: current_ect_period.started_on,
            school: current_school,
            teacher: future_mentor
          )
        end
        let!(:future_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            started_on: current_mentorship_period.finished_on.next_day,
            finished_on: current_mentorship_period.finished_on.next_year,
            mentee: current_ect_period,
            mentor: future_mentor_at_school_period
          )
        end

        let(:another_future_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "Jane", trs_last_name: "Smith")
        end
        let(:another_future_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: current_ect_period.started_on,
            school: current_school,
            teacher: another_future_mentor
          )
        end
        let!(:another_future_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            started_on: future_mentorship_period.finished_on.next_day,
            mentee: current_ect_period,
            mentor: another_future_mentor_at_school_period
          )
        end

        it "has current mentor's full name" do
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "Moby Dick",
            matcher: [:has_text?, { exact: false }]
          )
        end

        it "displays upcoming mentorship details in order" do
          upcoming_mentorship_detail = <<~TXT.squish
            John Smith (from #{future_mentorship_period.started_on.to_fs(:govuk)})
          TXT
          another_upcoming_mentorship_detail = <<~TXT.squish
            Jane Smith (from #{another_future_mentorship_period.started_on.to_fs(:govuk)})
          TXT
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "ul > li",
            matcher: [:has_css?, { count: 2 }]
          )
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "ul > li:nth-child(1)",
            matcher: [:has_css?, { text: upcoming_mentorship_detail }]
          )
          expect(subject).to have_summary_list_row(
            "Mentor",
            value: "ul > li:nth-child(2)",
            matcher: [:has_css?, { text: another_upcoming_mentorship_detail }]
          )
        end
      end

      context "when unassigned" do
        it "has instruction to assign" do
          expect(subject).to have_css("dt.govuk-summary-list__key", text: "Mentor")
          expect(subject).to have_css("dd.govuk-summary-list__value", text: "Assign a mentor for this ECT")
        end
      end
    end

    it "school start date" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "School start date")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: "January 2025")
    end

    it "working pattern" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Working pattern")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: "Full time")
    end

    it "status" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Status")
      expect(subject).to have_css("dd.govuk-summary-list__value .govuk-tag")
    end
  end

  describe "Induction details" do
    before do
      FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period:)
      teacher.reload # Reload to pick up the new induction period
    end

    it "has title" do
      expect(subject).to have_css("h2.govuk-heading-m", text: "Induction details")
    end

    it "shows the appropriate body that has claimed the induction" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Appropriate body")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: "Alpha Teaching School Hub")
    end

    it "shows induction start date" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Induction start date")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: 1.year.ago.to_date.to_fs(:govuk))
    end

    context "when no induction start date is available" do
      before do
        teacher.induction_periods.destroy_all
      end

      it "shows appropriate message" do
        expect(subject).to have_css("dd.govuk-summary-list__value", text: "Yet to be reported by the appropriate body")
      end
    end
  end

  describe "Training details" do
    it "has title" do
      expect(subject).to have_css("h2.govuk-heading-m", text: "Training details")
    end

    it "shows training programme" do
      expect(subject).to have_css("dt.govuk-summary-list__key", text: "Training programme")
      expect(subject).to have_css("dd.govuk-summary-list__value", text: "Provider-led")
    end

    context "when provider-led" do
      let(:training_programme) { "provider_led" }

      it "shows lead provider and delivery partner fields" do
        expect(subject).to have_css("dt.govuk-summary-list__key", text: "Lead provider")
        expect(subject).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
      end
    end

    context "when school-led" do
      let(:training_period) { FactoryBot.create(:training_period, :school_led, ect_at_school_period: current_ect_period, started_on: "2025-01-11", finished_on: nil) }
      let(:training_programme) { "school_led" }

      it "does not show lead provider and delivery partner fields" do
        expect(subject).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
        expect(subject).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
      end
    end
  end
end
