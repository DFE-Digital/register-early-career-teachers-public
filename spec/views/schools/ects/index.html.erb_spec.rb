RSpec.describe "schools/ects/index.html.erb" do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:teachers, [])
    assign(:number_of_teachers, 0)
    assign(:school, school)
    allow(school).to receive(:blocked_from_registering_new_ects?).and_return(false)
  end

  it "shows the Register an ECT starting at your school button" do
    render
    expect(rendered).to have_css("a.govuk-button", text: "Register an ECT starting at your school")
  end

  context "when there are no teachers" do
    before { render }

    it "shows a message that there are no registered ECTs" do
      expect(rendered).to have_css("div.govuk-grid-column-two-thirds p.govuk-body", text: "Your school currently has no registered early career teachers.")
    end

    it "shows the Register an ECT starting at your school button" do
      expect(rendered).to have_css("a.govuk-button", text: "Register an ECT starting at your school")
    end

    it "does not render the summary component" do
      expect(rendered).not_to have_css(".govuk-summary-card")
    end

    it "does not render the search box" do
      expect(rendered).not_to have_css(".govuk-form-group label", text: "Search by name or teacher reference number (TRN)")
    end
  end

  context "when there are teachers" do
    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Johnnie", trs_last_name: "Walker") }
    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }

    before do
      assign(:teachers, [teacher])
      assign(:number_of_teachers, 1)
      assign(:school, school)
      assign(:school_ect_periods, [ect_at_school_period])
      allow(school).to receive(:blocked_from_registering_new_ects?).and_return(false)

      render
    end

    it "renders the summary component" do
      expect(rendered).to have_css(".govuk-summary-card__title", text: "Johnnie Walker")
    end

    it "renders the search box" do
      expect(rendered).to have_css(".govuk-form-group label", text: "Search by name or teacher reference number (TRN)")
    end

    context "when there are no matching teachers" do
      before do
        assign(:teachers, [])
        allow(school).to receive(:blocked_from_registering_new_ects?).and_return(false)
        render
      end

      it "renders the no ects text" do
        expect(rendered).to have_css(".govuk-body", text: "There are no ECTs that match your search.")
      end

      it "renders the search box" do
        expect(rendered).to have_css(".govuk-form-group label", text: "Search by name or teacher reference number (TRN)")
      end
    end

    context "when teachers have passed or failed induction" do
      let(:passed_teacher) { FactoryBot.create(:teacher, trs_first_name: "Jack", trs_last_name: "Daniels", trs_induction_status: "Passed") }
      let(:failed_teacher) { FactoryBot.create(:teacher, trs_first_name: "Jim", trs_last_name: "Beam", trs_induction_status: "Failed") }

      before do
        passed_ect = FactoryBot.create(:ect_at_school_period, :ongoing, teacher: passed_teacher, school:)
        failed_ect = FactoryBot.create(:ect_at_school_period, :ongoing, teacher: failed_teacher, school:)
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period: passed_ect)
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period: failed_ect)

        render
      end

      # TODO induction completed date
      it "does not render summary components for completed teachers" do
        expect(rendered).to have_css(".govuk-summary-card__title", text: "Johnnie Walker")
        expect(rendered).not_to have_css(".govuk-summary-card__title", text: "Jack Daniels")
        expect(rendered).not_to have_css(".govuk-summary-card__title", text: "Jim Beam")
      end
    end
  end

  context "when registration is blocked" do
    before do
      assign(:teachers, [])
      assign(:number_of_teachers, 0)
      assign(:school, school)
      allow(school).to receive(:blocked_from_registering_new_ects?).and_return(true)
      render
    end

    it "does not show the Register an ECT starting at your school button" do
      expect(rendered).not_to have_css("a.govuk-button", text: "Register an ECT starting at your school")
    end

    it "shows a section 41 not approved message" do
      expect(rendered).to have_text("#{school.name} no longer has funding for early career teacher entitlement (ECTE). You cannot register new early career teachers.")
    end

    it "includes a link to eligibility and funding guidance" do
      expect(rendered).to have_link("eligibility and funding for ECTE", href: "https://www.gov.uk/guidance/funding-and-eligibility-for-ecf-based-training")
    end
  end
end
