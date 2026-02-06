RSpec.describe "admin/teachers/declarations/_declaration.html.erb", type: :view do
  let(:lead_provider) { FactoryBot.build_stubbed(:lead_provider, name: "Test Lead Provider") }
  let(:delivery_partner) { FactoryBot.build_stubbed(:delivery_partner, name: "Test Delivery Partner") }
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
        lead_provider:,
        delivery_partner:,
        for_ect?: true,
        for_mentor?: false,
        overall_status: "no_payment",
        events: Event.none
      )
    end
  end

  before do
    allow_any_instance_of(DeclarationHelper).to receive_messages(
      declaration_state_tag: "declaration-state-tag",
      declaration_course_identifier: "declaration-course-identifier"
    )
    render locals: { declaration: }
  end

  subject { Capybara.string(rendered) }

  it { is_expected.to have_summary_list_row("Declaration ID", value: "test-declaration-uuid", visible: :all) }
  it { is_expected.to have_summary_list_row("Course identifier", value: "declaration-course-identifier", visible: :all) }
  it { is_expected.to have_summary_list_row("Declaration type", value: "started", visible: :all) }
  it { is_expected.to have_summary_list_row("State", value: "declaration-state-tag", visible: :all) }
  it { is_expected.to have_summary_list_row("Declaration date and time", value: "15 January 2024, 12:00am", visible: :all) }
  it { is_expected.to have_summary_list_row("Lead provider", value: "Test Lead Provider", visible: :all) }
  it { is_expected.to have_summary_list_row("Evidence held", value: "training-event-attended", visible: :all) }

  describe "delivery partner" do
    context "when the declaration has no delivery partner" do
      let(:delivery_partner) { nil }

      it { is_expected.to have_summary_list_row("Delivery partner", value: "No delivery partner recorded", visible: :all) }
    end

    context "when the declaration has a delivery partner" do
      it { is_expected.to have_summary_list_row("Delivery partner", value: "Test Delivery Partner", visible: :all) }
    end
  end

  describe "state history" do
    context "when the declaration has no events" do
      it { is_expected.not_to have_content("State history") }
    end

    context "when the declaration has events" do
      let(:submitted_event) do
        FactoryBot.build_stubbed(
          :event,
          event_type: "teacher_declaration_created",
          heading: "Declaration submitted",
          happened_at: Time.zone.local(2024, 1, 15, 12, 0, 0)
        )
      end

      let(:voided_event) do
        FactoryBot.build_stubbed(
          :event,
          event_type: "teacher_declaration_voided",
          heading: "Declaration voided",
          happened_at: Time.zone.local(2024, 1, 16, 12, 0, 0)
        )
      end

      before do
        events_relation = double("events_relation", any?: true, earliest_first: [submitted_event, voided_event])
        allow(declaration).to receive(:events).and_return(events_relation)
        render locals: { declaration: }
      end

      it { is_expected.to have_content("State history") }

      it "displays the state history table" do
        # n.b. has_table? won't match <th>
        within "table" do
          within "tr:nth-child(1)" do
            is_expected.to have_css("th", text: "Submitted")
            is_expected.to have_css("td", text: "15 January 2024, 12:00pm")
          end
          within "tr:nth-child(2)" do
            is_expected.to have_css("Voided")
            is_expected.to have_css("16 January 2024, 12:00pm")
          end
        end
      end
    end
  end
end
