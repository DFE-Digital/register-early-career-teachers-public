RSpec.describe "schools/register_mentor_wizard/previous_training_period_details.html.erb" do
  let(:current_school) { FactoryBot.create(:school) }
  let(:mentor_teacher) { FactoryBot.create(:teacher) }

  let(:ect_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school: current_school) }

  let(:wizard_store) do
    FactoryBot.build(
      :session_repository,
      school_urn: current_school.urn,
      trn: mentor_teacher.trn,
      ect_id: ect_period.id
    )
  end

  let(:register_mentor_wizard) do
    FactoryBot.build(
      :register_mentor_wizard,
      current_step: :previous_training_period_details,
      store: wizard_store
    )
  end

  let(:mentor) { register_mentor_wizard.mentor }
  let(:decorated_mentor) { Schools::DecoratedMentor.new(mentor) }

  before do
    assign(:wizard, register_mentor_wizard)
    assign(:mentor, mentor)
    assign(:decorated_mentor, decorated_mentor)
  end

  context "when the mentor previously trained under a confirmed partnership" do
    let(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
    let(:confirmed_lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
    let(:confirmed_delivery_partner) { FactoryBot.create(:delivery_partner, name: "Rise Teaching School Hub") }

    let!(:active_lead_provider) do
      FactoryBot.create(
        :active_lead_provider,
        contract_period: current_contract_period,
        lead_provider: confirmed_lead_provider
      )
    end

    let!(:lead_provider_delivery_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        active_lead_provider:,
        delivery_partner: confirmed_delivery_partner
      )
    end

    let!(:mentor_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        teacher: mentor_teacher,
        school: current_school,
        started_on: Date.new(2024, 8, 1),
        finished_on: nil
      )
    end

    let!(:confirmed_training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :provider_led,
        mentor_at_school_period: mentor_period,
        school_partnership: FactoryBot.create(
          :school_partnership,
          school: current_school,
          lead_provider_delivery_partnership:
        ),
        started_on: Date.new(2024, 9, 1),
        finished_on: Date.new(2025, 7, 1)
      )
    end

    it "displays the confirmed lead provider and delivery partner names" do
      render

      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).to have_css("dd", text: "Ambition Institute")

      expect(rendered).to have_css("dt", text: "Delivery partner")
      expect(rendered).to have_css("dd", text: "Rise Teaching School Hub")
    end
  end

  context "when the mentor previously trained under a school-led programme" do
    before do
      allow(mentor).to receive(:previous_training_period).and_return(nil)
      allow(mentor).to receive_messages(previous_training_period: nil, previous_provider_led?: false)
    end

    it "shows a Lead provider row but does not display a Delivery partner row" do
      render

      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).not_to have_css("dt", text: "Delivery partner")
    end
  end

  context "when the mentor previously trained on a provider-led programme with only an expression of interest (no confirmed partnership)" do
    let(:previous_school) { FactoryBot.create(:school) }

    let!(:mentor_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        teacher: mentor_teacher,
        school: previous_school
      )
    end

    let(:lead_provider_from_eoi) { FactoryBot.create(:lead_provider, name: "EOI LP") }
    let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_from_eoi) }

    let!(:eoi_training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :provider_led,
        :ongoing,
        mentor_at_school_period: mentor_period,
        school_partnership: nil,
        expression_of_interest:
      )
    end

    it "shows the previous school name and 'Not confirmed' for lead provider and delivery partner" do
      render

      expect(rendered).to have_css("dt", text: "School name")
      expect(rendered).to have_css("dd", text: previous_school.name)

      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).to have_css("dd", text: "Not confirmed")

      expect(rendered).to have_css("dt", text: "Delivery partner")
      expect(rendered).to have_css("dd", text: "Not confirmed")
    end
  end
end
