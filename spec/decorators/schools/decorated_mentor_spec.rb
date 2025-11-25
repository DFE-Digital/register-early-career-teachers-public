RSpec.describe Schools::DecoratedMentor do
  let(:mentor) { double("Mentor") }
  let(:decorated_mentor) { described_class.new(mentor) }

  it "decorates a mentor-like object" do
    expect(decorated_mentor.__getobj__).to eq(mentor)
  end

  describe "#previous_school_name" do
    subject(:previous_school_name) { decorated_mentor.previous_school_name }

    let(:latest_registration_choice) { double("LatestRegistrationChoice", school:) }

    before do
      allow(mentor).to receive(:latest_registration_choice).and_return(latest_registration_choice)
    end

    context "when the latest registration choice has a school" do
      let(:school) { double("School", name: "Springfield Primary") }

      it "returns the school name" do
        expect(previous_school_name).to eq("Springfield Primary")
      end
    end

    context "when the latest registration choice has no school" do
      let(:school) { nil }

      it 'returns "Not confirmed"' do
        expect(previous_school_name).to eq("Not confirmed")
      end
    end

    context "when there is no latest registration choice" do
      let(:latest_registration_choice) { nil }

      it 'returns "Not confirmed"' do
        expect(previous_school_name).to eq("Not confirmed")
      end
    end
  end

  describe "#previous_lead_provider_name" do
    subject(:previous_lead_provider_name) { decorated_mentor.previous_lead_provider_name }

    let(:training_period) { double("TrainingPeriod", lead_provider_name:) }

    before do
      allow(mentor).to receive(:previous_confirmed_training_period).and_return(training_period)
    end

    context "when there is a previous training period" do
      let(:lead_provider_name) { "Lead Provider Ltd" }

      it "returns the lead provider name" do
        expect(previous_lead_provider_name).to eq("Lead Provider Ltd")
      end
    end

    context "when there is no previous training period" do
      let(:training_period) { nil }

      it 'returns "Not confirmed"' do
        expect(previous_lead_provider_name).to eq("Not confirmed")
      end
    end
  end

  describe "#previous_delivery_partner_name" do
    subject(:previous_delivery_partner_name) { decorated_mentor.previous_delivery_partner_name }

    let(:training_period) { double("TrainingPeriod", delivery_partner_name:) }

    before do
      allow(mentor).to receive(:previous_confirmed_training_period).and_return(training_period)
    end

    context "when there is a previous training period" do
      let(:delivery_partner_name) { "Delivery Partner Co" }

      it "returns the delivery partner name" do
        expect(previous_delivery_partner_name).to eq("Delivery Partner Co")
      end
    end

    context "when there is no previous training period" do
      let(:training_period) { nil }

      it 'returns "Not confirmed"' do
        expect(previous_delivery_partner_name).to eq("Not confirmed")
      end
    end
  end

  describe "#previous_registration_summary_rows" do
    subject(:rows) { decorated_mentor.previous_registration_summary_rows }

    let(:latest_registration_choice) { double("LatestRegistrationChoice", school:) }
    let(:training_period) do
      double(
        "TrainingPeriod",
        lead_provider_name:,
        delivery_partner_name:
      )
    end

    let(:school) { double("School", name: "Springfield Primary") }
    let(:lead_provider_name) { "Lead Provider Ltd" }
    let(:delivery_partner_name) { "Delivery Partner Co" }
    let(:previous_provider_led) { false }

    before do
      allow(mentor).to receive_messages(
        latest_registration_choice:,
        previous_confirmed_training_period: training_period,
        previous_provider_led?: previous_provider_led
      )
    end

    context "when the previous training was not provider-led" do
      let(:previous_provider_led) { false }

      it "includes school name and lead provider rows" do
        expect(rows.size).to eq(2)

        school_row = rows[0]
        lead_provider_row = rows[1]

        expect(school_row[:key][:text]).to eq("School name")
        expect(school_row[:value][:text]).to eq("Springfield Primary")

        expect(lead_provider_row[:key][:text]).to eq("Lead provider")
        expect(lead_provider_row[:value][:text]).to eq("Lead Provider Ltd")
      end

      it "does not include a delivery partner row" do
        keys = rows.map { |row| row[:key][:text] }
        expect(keys).not_to include("Delivery partner")
      end
    end

    context "when the previous training was provider-led" do
      let(:previous_provider_led) { true }

      it "includes a delivery partner row as the third row" do
        expect(rows.size).to eq(3)

        delivery_partner_row = rows[2]

        expect(delivery_partner_row[:key][:text]).to eq("Delivery partner")
        expect(delivery_partner_row[:value][:text]).to eq("Delivery Partner Co")
      end
    end

    context "when the previous training was provider-led but only an EOI exists" do
      let(:school) { double("School", name: "Springfield Primary") }
      let(:latest_registration_choice) { double("LatestRegistrationChoice", school:) }
      let(:training_period) { nil }
      let(:previous_provider_led) { true }

      it 'shows the school name and "Not confirmed" for lead provider and delivery partner' do
        expect(rows[0][:key][:text]).to eq("School name")
        expect(rows[0][:value][:text]).to eq("Springfield Primary")

        expect(rows[1][:key][:text]).to eq("Lead provider")
        expect(rows[1][:value][:text]).to eq("Not confirmed")

        expect(rows[2][:key][:text]).to eq("Delivery partner")
        expect(rows[2][:value][:text]).to eq("Not confirmed")
      end
    end

    context "when values are missing" do
      let(:latest_registration_choice) { nil }
      let(:training_period) { nil }
      let(:previous_provider_led) { true }

      it 'uses "Not confirmed" for missing values' do
        expect(rows[0][:value][:text]).to eq("Not confirmed")
        expect(rows[1][:value][:text]).to eq("Not confirmed")
        expect(rows[2][:value][:text]).to eq("Not confirmed")
      end
    end
  end
end
