RSpec.describe "admin/teachers/declarations/_declaration.html.erb", type: :view do
  subject { Capybara.string(rendered) }

  let(:lead_provider) { FactoryBot.build_stubbed(:lead_provider, name: "Test Lead Provider") }
  let(:delivery_partner_when_created) { FactoryBot.build_stubbed(:delivery_partner, name: "Test Delivery Partner") }
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
        delivery_partner_when_created:,
        for_ect?: true,
        for_mentor?: false,
        overall_status: "no_payment",
        events: Event.none,
        billable_or_changeable?: false
      )
    end
  end

  before do
    # rubocop:disable RSpec/AnyInstance - needed for boundary with a helper
    allow_any_instance_of(DeclarationHelper).to receive_messages(
      declaration_state_tag: "declaration-state-tag",
      declaration_course_identifier: "declaration-course-identifier"
    )
    # rubocop:enable RSpec/AnyInstance

    render locals: { declaration: }
  end

  it { is_expected.to have_summary_list_row("Declaration ID", value: "test-declaration-uuid", visible: :all) }
  it { is_expected.to have_summary_list_row("Course identifier", value: "declaration-course-identifier", visible: :all) }
  it { is_expected.to have_summary_list_row("Declaration type", value: "started", visible: :all) }
  it { is_expected.to have_summary_list_row("State", value: "declaration-state-tag", visible: :all) }
  it { is_expected.to have_summary_list_row("Declaration date and time", value: "15 January 2024, 12:00am", visible: :all) }
  it { is_expected.to have_summary_list_row("Lead provider", value: "Test Lead Provider", visible: :all) }
  it { is_expected.to have_summary_list_row("Evidence held", value: "training-event-attended", visible: :all) }
  it { is_expected.to have_summary_list_row("Delivery partner", value: "Test Delivery Partner", visible: :all) }

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
        within "table tbody tr:nth-child(1)" do
          expect(page).to have_css("th", text: "Submitted")
          expect(page).to have_css("td", text: "15 January 2024, 12:00pm")
        end
        within "table tbody tr:nth-child(2)" do
          expect(page).to have_css("th", text: "Voided")
          expect(page).to have_css("td", text: "16 January 2024, 12:00pm")
        end
      end

      context "when voided by an admin user" do
        let(:admin_user) { FactoryBot.build_stubbed(:user, name: "Admin User", email: "admin@example.com") }

        before do
          allow(declaration).to receive(:voided_by_user).and_return(admin_user)
          render locals: { declaration: }
        end

        it "shows who voided the declaration" do
          within "table tbody tr:nth-child(2)" do
            expect(page).to have_content("Voided by Admin User (admin@example.com)")
          end
        end
      end

      context "when voided by a lead provider" do
        before do
          allow(declaration).to receive(:voided_by_user).and_return(nil)
          render locals: { declaration: }
        end

        it "shows it was voided by lead provider" do
          within "table tbody tr:nth-child(2)" do
            expect(page).to have_content("Voided by lead provider")
          end
        end
      end
    end
  end

  describe "void declaration button" do
    subject { rendered }

    before do
      allow(declaration).to receive(:billable_or_changeable?).and_return(billable_or_changeable)
      render locals: { declaration: }
    end

    context "when the declaration can be voided by admin" do
      let(:billable_or_changeable) { true }

      it { is_expected.to have_css("a.govuk-button--warning", text: "Void declaration", visible: :all) }
    end

    context "when the declaration cannot be voided by admin" do
      let(:billable_or_changeable) { false }

      it { is_expected.not_to have_link("Void declaration", visible: :all) }
    end
  end
end
