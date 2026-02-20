RSpec.describe Schools::DecoratedSchool do
  let(:school) { FactoryBot.create(:school) }
  let(:decorated_school) { Schools::DecoratedSchool.new(school) }
  let(:contract_period) { FactoryBot.create(:contract_period) }

  it "decorates a School" do
    expect(decorated_school.__getobj__).to be_a(School)
  end

  describe "#latest_registration_choices" do
    let(:fake_latest_registration_choices) { double("Schools::LatestRegistrationChoices") }

    before do
      allow(Schools::LatestRegistrationChoices).to receive(:new)
                                                     .with(school: decorated_school, contract_period:)
                                                     .and_return(fake_latest_registration_choices)
    end

    it "returns a Schools::LatestRegistrationChoices object" do
      expect(decorated_school.latest_registration_choices(contract_period:)).to eql(fake_latest_registration_choices)
    end

    context "when we are on the last day of the contract period" do
      around do |example|
        travel_to(contract_period.finished_on) do
          example.run
        end
      end

      it "finds a contract period and returns a Schools::LatestRegistrationChoices object" do
        expect(Schools::LatestRegistrationChoices).to receive(:new).with(school: decorated_school, contract_period:)
        decorated_school.latest_registration_choices
      end
    end
  end

  describe "#has_partnership_with?" do
    subject { decorated_school.has_partnership_with?(lead_provider:, contract_period:) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:fake_partnership_check) { double("SchoolPartnerships::Search", exists?: true) }

    before do
      allow(SchoolPartnerships::Search).to receive(:new)
                                             .with(lead_provider:, contract_period:)
                                             .and_return(fake_partnership_check)
    end

    it "creates a SchoolPartnerships::Search and calls #exists?" do
      expect(subject).to be(true)
      expect(fake_partnership_check).to have_received(:exists?).once
      expect(SchoolPartnerships::Search).to have_received(:new).with(lead_provider:, contract_period:)
    end
  end

  describe "#needs_lead_provider_confirmation_message?" do
    subject(:needs_message) { decorated_school.needs_lead_provider_confirmation_message?(ect:) }

    let(:ect) { double("ECT", contract_start_date: start_date) }
    let(:start_date) { Date.new(2025, 1, 1) }

    let(:lead_provider) { double("LeadProvider") }
    let(:latest_registration_choices) { double("Schools::LatestRegistrationChoices", lead_provider:) }

    before do
      allow(decorated_school)
        .to receive(:provider_led_training_programme_chosen?)
        .and_return(provider_led)

      allow(decorated_school)
        .to receive_messages(provider_led_training_programme_chosen?: provider_led, latest_registration_choices:)

      allow(decorated_school)
        .to receive(:lacks_partnership_with?)
        .with(lead_provider:, contract_period: start_date)
        .and_return(!has_partnership)
    end

    context "when the training programme is not provider-led" do
      let(:provider_led) { false }
      let(:has_partnership) { false }

      it { is_expected.to be(false) }
    end

    context "when provider-led but no lead provider is present" do
      let(:provider_led) { true }
      let(:has_partnership) { false }
      let(:lead_provider) { nil }

      it { is_expected.to be(false) }
    end

    context "when provider-led but ect has no contract_start_date" do
      let(:provider_led) { true }
      let(:has_partnership) { false }
      let(:start_date) { nil }

      it { is_expected.to be(false) }
    end

    context "when provider-led, lead provider and start date present, and there is already a partnership" do
      let(:provider_led) { true }
      let(:has_partnership) { true }

      it "returns false" do
        expect(needs_message).to be(false)
      end
    end

    context "when provider-led, lead provider and start date present, and there is no partnership" do
      let(:provider_led) { true }
      let(:has_partnership) { false }

      it "returns true" do
        expect(needs_message).to be(true)
      end
    end
  end

  describe "#lead_provider_name" do
    subject(:lead_provider_name) { decorated_school.lead_provider_name }

    let(:lead_provider) { double("LeadProvider", name: "Test Lead Provider") }
    let(:latest_registration_choices) { double("Schools::LatestRegistrationChoices", lead_provider:) }

    before do
      allow(decorated_school).to receive(:latest_registration_choices).and_return(latest_registration_choices)
    end

    context "when latest registration choices has a lead provider" do
      it "returns the lead provider name" do
        expect(lead_provider_name).to eq("Test Lead Provider")
      end
    end

    context "when there is no lead provider" do
      let(:lead_provider) { nil }

      it "returns nil" do
        expect(lead_provider_name).to be_nil
      end
    end
  end
end
