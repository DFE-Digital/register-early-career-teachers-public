RSpec.describe Admin::DeliveryPartners::ChangeName do
  subject(:service) do
    described_class.new(
      delivery_partner:,
      proposed_name:,
      author:
    )
  end

  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Alpha") }
  let(:user)             { FactoryBot.create(:user, :admin) }
  let(:author)           { Sessions::Users::DfEPersona.new(email: user.email) }

  before do
    allow(Events::Record).to receive(:record_delivery_partner_name_changed_event!)
  end

  describe "#rename!" do
    context "when the proposed name is valid" do
      let(:proposed_name) { "Beta" }

      it "returns the same instance and records an event" do
        result = service.rename!

        expect(result).to be(delivery_partner)
        expect(Events::Record).to have_received(:record_delivery_partner_name_changed_event!)
          .with(delivery_partner:, author:, from: "Alpha", to: "Beta")
      end
    end

    context "when the proposed name is valid and has extra spaces" do
      let(:proposed_name) { "A   Alpha" }

      it "updates the record (squished) and returns the same instance" do
        result = service.rename!

        expect(result).to be(delivery_partner)
        expect(result.name).to eq("A Alpha")
        expect(delivery_partner.reload.name).to eq("A Alpha")

        expect(Events::Record).to have_received(:record_delivery_partner_name_changed_event!)
          .with(delivery_partner:, author:, from: "Alpha", to: "A Alpha")
      end
    end

    context "when the proposed name differs only by case/whitespace" do
      let(:proposed_name) { "  alpha " }

      it "returns the same instance, unchanged, and records no event" do
        result = service.rename!

        expect(result).to be(delivery_partner)
        expect(result.name).to eq("Alpha")
        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Events::Record).not_to have_received(:record_delivery_partner_name_changed_event!)
      end
    end

    context "when the proposed name is blank" do
      let(:proposed_name) { "   " }

      it "raises and leaves state unchanged" do
        expect { service.rename! }.to raise_error(ActiveRecord::RecordInvalid)

        expect(delivery_partner.errors.added?(:name, :blank)).to be(true)
        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Events::Record).not_to have_received(:record_delivery_partner_name_changed_event!)
      end
    end

    context "when the proposed name duplicates another delivery partner (case-insensitive)" do
      let!(:other_dp) { FactoryBot.create(:delivery_partner, name: "Taken") }
      let(:proposed_name) { " taken  " }

      it "raises and does not change anything" do
        expect { service.rename! }.to raise_error(ActiveRecord::RecordInvalid)

        expect(delivery_partner.errors[:name])
          .to include("A delivery partner with this name already exists")
        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Events::Record).not_to have_received(:record_delivery_partner_name_changed_event!)
      end
    end

    context "when the update raises ActiveRecord::RecordInvalid" do
      let(:proposed_name) { "Gamma" }

      before do
        allow(delivery_partner).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(delivery_partner))
        allow(delivery_partner).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(delivery_partner))
      end

      it "raises and does not change the record or record an event" do
        expect { service.rename! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Events::Record).not_to have_received(:record_delivery_partner_name_changed_event!)
      end
    end

    context "when event creation fails" do
      let(:proposed_name) { "Delta" }

      before do
        allow(Events::Record).to receive(:record_delivery_partner_name_changed_event!)
          .and_raise(StandardError)
      end

      it "rolls back the name change" do
        expect { service.rename! }.to raise_error(StandardError)
        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Events::Record).to have_received(:record_delivery_partner_name_changed_event!)
      end
    end
  end
end
