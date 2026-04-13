RSpec.describe Admin::Schools::TeachersTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject { page }

  let(:school) { FactoryBot.create(:school) }
  let(:component) { described_class.new(school:) }

  context "when there are no teachers" do
    before { render_inline(component) }

    it { is_expected.to have_css("p", text: "No teachers found at this school.") }
    it { is_expected.not_to have_css("table.govuk-table") }
  end

  context "when there are teachers" do
    let!(:ect) do
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, school:, started_on: Date.new(2022, 7, 1))
      school_partnership = FactoryBot.create(:school_partnership, :for_year, school:, year: 2022)
      FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, school_partnership:)
      ect_at_school_period.teacher
    end

    let!(:mentor) do
      mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: Date.new(2023, 7, 1))
      school_partnership = FactoryBot.create(:school_partnership, :for_year, school:, year: 2023)
      FactoryBot.create(:training_period, :provider_led, :for_mentor, :with_schedule, :ongoing, mentor_at_school_period:, school_partnership:)
      mentor_at_school_period.teacher
    end

    let!(:ect_and_mentor) do
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, school:, started_on: Date.new(2024, 7, 1))
      school_partnership = FactoryBot.create(:school_partnership, :for_year, school:, year: 2024)
      FactoryBot.create(:training_period, :ongoing, ect_at_school_period:, school_partnership:)

      mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: ect_at_school_period.teacher, started_on: Date.new(2025, 7, 1))
      school_partnership = FactoryBot.create(:school_partnership, :for_year, school:, year: 2025)
      FactoryBot.create(:training_period, :provider_led, :for_mentor, :with_schedule, :ongoing, mentor_at_school_period:, school_partnership:)

      ect_at_school_period.teacher
    end

    let!(:ect_eoi) do
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, school:, started_on: Date.new(2026, 7, 1))
      expression_of_interest = FactoryBot.create(:active_lead_provider, :for_year, year: 2026)
      FactoryBot.create(:training_period, :provider_led, :with_only_expression_of_interest, ect_at_school_period:, expression_of_interest:)
      ect_at_school_period.teacher
    end

    let!(:ect_without_training_period) do
      FactoryBot.create(:ect_at_school_period, school:, started_on: Date.new(2025, 7, 1)).teacher
    end

    let!(:mentor_without_training_period) do
      FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: Date.new(2025, 7, 1)).teacher
    end

    let!(:ect_at_different_school) do
      FactoryBot.create(:ect_at_school_period, started_on: Date.new(2025, 7, 1)).teacher
    end

    before { render_inline component }

    shared_examples "row" do |contract_period_year|
      subject { page.find "tr", text: teacher.trn }

      it { is_expected.to have_link(Teachers::Name.new(teacher).full_name, href: admin_teacher_induction_path(teacher)) }
      it { is_expected.to have_css("td", text: Teachers::Role.new(teacher:).to_s) }
      it { is_expected.to have_css("td", text: contract_period_year) }
    end

    it { is_expected.to have_css("tbody tr", count: 6) }
    it { is_expected.not_to have_css("td", text: ect_at_different_school.trn) }

    describe "table headers" do
      subject { page.find "thead" }

      it { is_expected.to have_css("th", text: "Name") }
      it { is_expected.to have_css("th", text: "TRN") }
      it { is_expected.to have_css("th", text: "Type") }
      it { is_expected.to have_css("th", text: "Contract period") }
    end

    describe "the ECT row" do
      let(:teacher) { ect }

      include_examples "row", "2022"
    end

    describe "the mentor row" do
      let(:teacher) { mentor }

      include_examples "row", "2023"
    end

    describe "the ECT and mentor row" do
      let(:teacher) { ect_and_mentor }

      include_examples "row", "2025"
    end

    describe "the ECT EOI row" do
      let(:teacher) { ect_eoi }

      include_examples "row", "2026"
    end

    describe "the ECT without training period row" do
      let(:teacher) { ect_without_training_period }

      include_examples "row", "No training period"
    end

    describe "the mentor without training period row" do
      let(:teacher) { mentor_without_training_period }

      include_examples "row", "No training period"
    end
  end
end
