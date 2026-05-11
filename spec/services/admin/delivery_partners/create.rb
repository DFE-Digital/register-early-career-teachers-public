RSpec.describe Admin::DeliveryPartners::Create do
  subject(:service) { described_class.new(name:, author:) }

  let(:user)   { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:name)   { "Ambition Institute" }

  before do
    allow(Events::Record).to receive(:record_delivery_partner_created_event!)
  end

  describe "#create!" do
    context "when name is valid" do
      it "creates a delivery partner" do
        expect { service.create! }.to change(DeliveryPartner, :count).by(1)
      end

      it "returns the persisted delivery partner" do
        result = service.create!
        expect(result).to be_a(DeliveryPartner)
        expect(result).to be_persisted
      end

      it "sets the name" do
        expect(service.create!.name).to eq("Ambition Institute")
      end

      it "generates an api_id" do
        expect(service.create!.api_id).to be_present
      end

      it "records a delivery_partner_created event" do
        service.create!
        expect(Events::Record).to have_received(:record_delivery_partner_created_event!)
          .with(delivery_partner: instance_of(DeliveryPartner), author:)
      end
    end

    context "when name has extra whitespace" do
      let(:name) { "  Ambition   Institute  " }

      it "squishes the name" do
        expect(service.create!.name).to eq("Ambition Institute")
      end
    end

    context "when name is blank" do
      let(:name) { "" }

      it "raises ActiveRecord::RecordInvalid" do
        expect { service.create! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not create a delivery partner" do
        expect { service.create! }.not_to change(DeliveryPartner, :count)
      end

      it "does not record an event" do
        begin
          service.create!
        rescue StandardError
          nil
        end
        expect(Events::Record).not_to have_received(:record_delivery_partner_created_event!)
      end
    end

    context "when name is a duplicate" do
      before { FactoryBot.create(:delivery_partner, name: "Ambition Institute") }

      it "raises ActiveRecord::RecordInvalid" do
        expect { service.create! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not create a delivery partner" do
        expect { service.create! }.not_to change(DeliveryPartner, :count)
      end

      it "does not record an event" do
        begin
          service.create!
        rescue StandardError
          nil
        end
        expect(Events::Record).not_to have_received(:record_delivery_partner_created_event!)
      end
    end

    context "when event creation fails" do
      before do
        allow(Events::Record).to receive(:record_delivery_partner_created_event!)
          .and_raise(StandardError)
      end

      it "rolls back the delivery partner creation" do
        expect { service.create! }.to raise_error(StandardError)
        expect(DeliveryPartner.where(name: "Ambition Institute")).not_to exist
      end

      it "does not persist the delivery partner" do
        expect {
          begin
            service.create!
          rescue StandardError
            nil
          end
        }.not_to change(DeliveryPartner, :count)
      end
    end
  end
end
