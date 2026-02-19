RSpec.describe UnclaimedIndex::TableSectionComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(
      ect_at_school_periods:,
      pagy:,
      row_component:
    )
  end

  let(:pagy) { double("Pagy", count: 25, page: 1, limit: 20, pages: 2, series: [1, 2], vars: {}, prev: nil, next: 2) }

  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  let(:postman_pat) do
    FactoryBot.create(:teacher,
                      trs_first_name: "Postman",
                      trs_last_name: "Pat",
                      trn: "1234567",
                      trs_initial_teacher_training_provider_name: "ITT")
  end

  let(:bob_builder) do
    FactoryBot.create(:teacher,
                      trs_first_name: "Bob",
                      trs_last_name: "Builder",
                      trn: "2345678",
                      trs_initial_teacher_training_provider_name: "ITT")
  end

  let!(:postman_pat_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: postman_pat, school:) }
  let!(:bob_builder_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: bob_builder, school:) }

  let!(:induction_period) { FactoryBot.create(:induction_period, :ongoing, teacher: postman_pat, appropriate_body_period:) }

  let(:ect_at_school_periods) do
    ECTAtSchoolPeriod
      .where(id: [postman_pat_at_school_period.id, bob_builder_at_school_period.id])
      .with_teacher
      .with_school
      .with_teacher_current_induction_period_appropriate_body
  end

  context "with no ect_at_school_periods" do
    let(:ect_at_school_periods) { ECTAtSchoolPeriod.none }
    let(:row_component) { UnclaimedIndex::NoQts::TableRowComponent }

    it "does not render a table" do
      expect(rendered.css("table").length).to eq(0)
    end

    it "renders empty state message" do
      expect(rendered.to_html).to include("There are no ECTs to display.")
    end
  end

  context "with NoQts::TableRowComponent" do
    let(:row_component) { UnclaimedIndex::NoQts::TableRowComponent }

    it "renders the correct headings" do
      headers = rendered.css("th").map(&:text)
      expect(headers).to contain_exactly("Name", "TRN", "School name", "School start date", "Induction tutor email")
    end

    it "renders a row for each period" do
      expect(rendered.css("tbody tr").length).to eq(2)
    end

    it "renders teacher names, TRNs, school name, and induction tutor email" do
      html = rendered.to_html
      expect(html).to include("Postman Pat")
      expect(html).to include("1234567")
      expect(html).to include("Bob Builder")
      expect(html).to include("2345678")
      expect(html).to include(school.name)
      expect(html).to include(school.induction_tutor_email)
    end

    it "renders pagination" do
      expect(rendered.to_html).to include("pagination")
    end
  end

  context "with Claimable::TableRowComponent" do
    let(:row_component) { UnclaimedIndex::Claimable::TableRowComponent }

    it "renders the correct headings" do
      headers = rendered.css("th").map(&:text)
      expect(headers).to contain_exactly("Name", "TRN", "School name", "School start date", "Induction tutor email", "ITT provider", "")
    end

    it "renders ITT provider name" do
      expect(rendered.to_html).to include("ITT")
    end

    it "renders a claim link with TRN" do
      expect(rendered).to have_link("Claim", href: /find-ect\/new\?trn=1234567/)
    end
  end

  context "with ClaimedByAnother::TableRowComponent" do
    let(:row_component) { UnclaimedIndex::ClaimedByAnother::TableRowComponent }

    it "renders the correct headings" do
      headers = rendered.css("th").map(&:text)
      expect(headers).to contain_exactly("Name", "TRN", "School name", "School start date", "Induction tutor email", "Current AB")
    end

    it "renders the current appropriate body name" do
      expect(rendered.to_html).to include(appropriate_body_period.name)
    end
  end
end
