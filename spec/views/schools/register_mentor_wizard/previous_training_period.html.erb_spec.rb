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

  before do
    assign(:wizard, register_mentor_wizard)
    assign(:mentor, mentor)
  end

  context "when the mentor previously trained under a confirmed partnership" do
    let(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
    let(:confirmed_lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
    let(:confirmed_delivery_partner) { FactoryBot.create(:delivery_partner, name: "Rise Teaching School Hub") }

    let!(:active_lead_provider) do
      FactoryBot.create(:active_lead_provider, contract_period: current_contract_period, lead_provider: confirmed_lead_provider)
    end

    let!(:lead_provider_delivery_partnership) do
      FactoryBot.create(:lead_provider_delivery_partnership,
                        active_lead_provider:,
                        delivery_partner: confirmed_delivery_partner)
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
        school_partnership: FactoryBot.create(:school_partnership,
                                              school: current_school,
                                              lead_provider_delivery_partnership:),
        started_on: Date.new(2024, 9, 1),
        finished_on: Date.new(2025, 7, 1)
      )
    end

    it "displays the correct lead provider and delivery partner names" do
      render

      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).to have_css("dd", text: "Ambition Institute")

      expect(rendered).to have_css("dt", text: "Delivery partner")
      expect(rendered).to have_css("dd", text: "Rise Teaching School Hub")
    end
  end

  context "when the mentor previously trained under a school-led programme" do
    before do
      instance_double(
        TrainingPeriod,
        lead_provider_name: nil,
        delivery_partner_name: nil,
        provider_led_training_programme?: false
      )

      allow(mentor).to receive(:previous_provider_led?)
        .and_return(false)
    end

    it "shows the lead provider but does not display a delivery partner row" do
      render

      expect(rendered).to have_css("dt", text: "Lead provider")
      expect(rendered).not_to have_css("dt", text: "Delivery partner")
    end
  end
end
