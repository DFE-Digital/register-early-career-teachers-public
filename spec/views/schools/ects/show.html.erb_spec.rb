RSpec.describe "schools/ects/show.html.erb" do
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
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Alpha Teaching School Hub") }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Barry", trs_last_name: "White", corrected_name: "Baz White") }
  let(:previous_school) { FactoryBot.create(:school, urn: "123456") }
  let(:current_school) { FactoryBot.create(:school, :state_funded, urn: "987654") }
  let(:requested_appropriate_body) { FactoryBot.create(:appropriate_body, name: "Requested AB") }
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

    render
  end

  it "has title" do
    expect(view.content_for(:page_title)).to eql("Baz White")
  end

  it "includes a back button that links to the school home page" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: schools_ects_home_path)
  end

  describe "ECT details" do
    it "title" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "ECT details")
    end

    it "full name" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Name")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Baz White")
    end

    it "current email address" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Email address")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: "love@whale.com")
    end

    describe "mentor" do
      context "when assigned" do
        before do
          mentor = FactoryBot.create(:teacher, trs_first_name: "Moby", trs_last_name: "Dick")
          mentor_at_school_period = FactoryBot.create(:mentor_at_school_period,
                                                      started_on: current_ect_period.started_on,
                                                      finished_on: nil,
                                                      school: current_school,
                                                      teacher: mentor)

          FactoryBot.create(:mentorship_period, :ongoing,
                            started_on: current_ect_period.started_on,
                            mentee: current_ect_period,
                            mentor: mentor_at_school_period)

          render
        end

        it "has mentor's full name" do
          expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Mentor")
          expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Moby Dick")
        end
      end

      context "when unassigned" do
        it "has instruction to assign" do
          expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Mentor")
          expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Assign a mentor for this ECT")
        end
      end
    end

    it "school start date" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "School start date")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: "January 2025")
    end

    it "working pattern" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Working pattern")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Full time")
    end

    it "status" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Status")
      expect(rendered).to have_css("dd.govuk-summary-list__value .govuk-tag")
    end
  end

  describe "Induction details" do
    before do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:)
      teacher.reload # Reload to pick up the new induction period
      render
    end

    it "has title" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "Induction details")
    end

    it "shows appropriate body" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Appropriate body")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Requested AB")
    end

    it "shows induction start date" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Induction start date")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: 1.year.ago.to_date.to_fs(:govuk))
    end

    context "when no induction start date is available" do
      before do
        teacher.induction_periods.destroy_all
        render
      end

      it "shows appropriate message" do
        expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Yet to be reported by the appropriate body")
      end
    end
  end

  describe "Training details" do
    before do
      render
    end

    it "has title" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "Training details")
    end

    it "shows training programme" do
      expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Training programme")
      expect(rendered).to have_css("dd.govuk-summary-list__value", text: "Provider-led")
    end

    context "when provider-led" do
      let(:training_programme) { "provider_led" }

      it "shows lead provider and delivery partner fields" do
        expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Lead provider")
        expect(rendered).to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
      end
    end

    context "when school-led" do
      let(:training_period) { FactoryBot.create(:training_period, :school_led, ect_at_school_period: current_ect_period, started_on: "2025-01-11", finished_on: nil) }
      let(:training_programme) { "school_led" }

      it "does not show lead provider and delivery partner fields" do
        expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Lead provider")
        expect(rendered).not_to have_css("dt.govuk-summary-list__key", text: "Delivery partner")
      end
    end
  end
end
