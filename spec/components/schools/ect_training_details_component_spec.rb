RSpec.describe Schools::ECTTrainingDetailsComponent, type: :component do
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Ambition Institute') }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'Test Delivery Partner') }
  let(:active_lead_provider) { FactoryBot.build(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.build(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.build(:school_partnership, lead_provider_delivery_partnership:, school: ect_at_school_period.school) }
  let(:teacher) { FactoryBot.create(:teacher, trn: '9876543', trs_first_name: 'John', trs_last_name: 'Doe') }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
  let(:training_period) { FactoryBot.build(:training_period, ect_at_school_period:, school_partnership:) }

  let(:component) { described_class.new(ect_at_school_period:, training_period:) }

  before { render_inline(component) }

  it "renders the section heading" do
    expect(page).to have_selector('h2.govuk-heading-m', text: 'Training details')
  end

  it "renders the training programme row" do
    expect(page).to have_summary_list_row("Training programme")
  end

  context "when there is no training period" do
    let(:training_period) { nil }

    it "renders nothing" do
      expect(page).to have_no_selector("body")
    end
  end

  context 'when provider-led training' do
    let(:training_period) { FactoryBot.build(:training_period, :provider_led, ect_at_school_period:) }

    it "shows lead provider information" do
      expect(page).to have_summary_list_row(
        "Lead provider",
        value: "Not available"
      )
    end

    it "shows delivery partner information" do
      expect(page).to have_summary_list_row(
        "Delivery partner",
        value: "Yet to be reported by the lead provider"
      )
    end

    context 'with confirmed partnership' do
      it "shows lead provider information" do
        expect(page).to have_summary_list_row(
          "Lead provider",
          value: "Not available"
        )
      end

      it "shows delivery partner information" do
        expect(page).to have_summary_list_row(
          "Delivery partner",
          value: "Yet to be reported by the lead provider"
        )
      end
    end

    context 'with expression of interest only' do
      let(:training_period) { FactoryBot.build(:training_period, :provider_led, ect_at_school_period:) }

      it "shows lead provider information" do
        expect(page).to have_summary_list_row(
          "Lead provider",
          value: "Not available"
        )
      end

      it "shows delivery partner information" do
        expect(page).to have_summary_list_row(
          "Delivery partner",
          value: "Yet to be reported by the lead provider"
        )
      end
    end
  end

  context 'when school-led training' do
    let(:training_period) { FactoryBot.build(:training_period, :school_led, ect_at_school_period:) }

    it "does not show lead provider information" do
      expect(page).not_to have_summary_list_row("Lead provider")
    end

    it "does not show delivery partner information" do
      expect(page).not_to have_summary_list_row("Delivery partner")
    end
  end

  describe '#training_programme_display_name' do
    context 'when training programme is provider_led' do
      let(:training_period) { FactoryBot.build(:training_period, :provider_led, ect_at_school_period:) }

      it 'displays Provider-led' do
        expect(page).to have_summary_list_row(
          "Training programme",
          value: "Provider-led"
        )
      end
    end

    context 'when training programme is school_led' do
      let(:training_period) { FactoryBot.build(:training_period, :school_led, ect_at_school_period:) }

      it 'displays School-led' do
        expect(page).to have_summary_list_row(
          "Training programme",
          value: "School-led"
        )
      end
    end

    context 'when training programme is nil' do
      let(:training_period) { FactoryBot.build(:training_period, ect_at_school_period:, training_programme: nil) }

      it 'displays Unknown' do
        expect(page).to have_summary_list_row(
          "Training programme",
          value: "Unknown"
        )
      end
    end
  end
end
