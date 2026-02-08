RSpec.describe "admin/teachers/declarations/index.html.erb" do
  let(:teacher) do
    FactoryBot.build_stubbed(
      :teacher,
      trn: "1234567",
      trs_first_name: "Floella",
      trs_last_name: "Benjamin"
    )
  end

  let(:declaration) do
    FactoryBot.build_stubbed(
      :declaration,
      declaration_type: "started",
      declaration_date: Date.new(2024, 1, 15),
      api_id: "test-declaration-uuid",
      evidence_type: "training-event-attended"
    ).tap do |d|
      allow(d).to receive_messages(
        api_id: "test-declaration-uuid",
        lead_provider: FactoryBot.build_stubbed(:lead_provider),
        delivery_partner_when_created: FactoryBot.build_stubbed(:delivery_partner),
        for_ect?: true,
        for_mentor?: false,
        overall_status: "no_payment",
        events: Event.none
      )
    end
  end

  before do
    assign(:teacher, teacher)
    assign(:breadcrumbs, { "Teachers" => "/admin/teachers", "Floella Benjamin" => "/admin/teachers/#{teacher.id}", "Declarations" => nil })
    assign(:navigation_items, [])
    assign(:ect_declarations, ect_declarations)
    assign(:mentor_declarations, mentor_declarations)
    render
  end

  context "when the teacher has no declarations" do
    let(:ect_declarations) { [] }
    let(:mentor_declarations) { [] }

    it "displays the ECT empty state message" do
      expect(rendered).to include("There are no ECT training declarations for Floella Benjamin")
    end

    it "displays the mentor empty state message" do
      expect(rendered).to include("There are no mentor training declarations for Floella Benjamin")
    end

    it "displays the ECT training declarations heading" do
      expect(rendered).to include("ECT training declarations")
    end

    it "displays the mentor training declarations heading" do
      expect(rendered).to include("Mentor training declarations")
    end
  end

  context "when the teacher has ECT declarations but no mentor declarations" do
    let(:ect_declarations) { [declaration] }
    let(:mentor_declarations) { [] }

    it "does not display the ECT empty state message" do
      expect(rendered).not_to include("There are no ECT training declarations for")
    end

    it "displays the mentor empty state message" do
      expect(rendered).to include("There are no mentor training declarations for Floella Benjamin")
    end

    it "renders the declaration partial" do
      expect(rendered).to include(declaration.api_id)
    end
  end

  context "when the teacher has mentor declarations but no ECT declarations" do
    let(:mentor_declaration) do
      FactoryBot.build_stubbed(
        :declaration,
        declaration_type: "started",
        declaration_date: Date.new(2024, 1, 15),
        api_id: "test-mentor-declaration-uuid",
        evidence_type: "training-event-attended"
      ).tap do |d|
        allow(d).to receive_messages(
          api_id: "test-mentor-declaration-uuid",
          lead_provider: FactoryBot.build_stubbed(:lead_provider),
          delivery_partner_when_created: FactoryBot.build_stubbed(:delivery_partner),
          for_ect?: false,
          for_mentor?: true,
          overall_status: "no_payment",
          events: Event.none
        )
      end
    end

    let(:ect_declarations) { [] }
    let(:mentor_declarations) { [mentor_declaration] }

    it "displays the ECT empty state message" do
      expect(rendered).to include("There are no ECT training declarations for Floella Benjamin")
    end

    it "does not display the mentor empty state message" do
      expect(rendered).not_to include("There are no mentor training declarations for")
    end

    it "renders the mentor declaration" do
      expect(rendered).to include(mentor_declaration.api_id)
    end
  end
end
