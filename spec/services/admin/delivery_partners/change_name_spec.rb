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

  describe "#rename!" do
    context "when the proposed name is valid" do
      let(:proposed_name) { "Beta" }

      it "returns the same instance" do
        expect(service.rename!).to be(delivery_partner)
      end

      it "enqueues an event" do
        expect { service.rename! }
          .to have_enqueued_job(RecordEventJob).with(hash_including(
                                                       event_type: :delivery_partner_name_changed,
                                                       delivery_partner:,
                                                       metadata: include("name" => %w[Alpha Beta])
                                                     ))
      end
    end

    context "when the proposed name is valid and has spaces between words" do
      let(:proposed_name) { "A Alpha" }

      it "returns the same instance, updated" do
        result = service.rename!

        expect(result).to be(delivery_partner)

        expect(result.name).to eq("A Alpha")
        expect(delivery_partner.reload.name).to eq("A Alpha")
      end

      it "enqueues an event" do
        expect { service.rename! }
          .to have_enqueued_job(RecordEventJob).with(
            hash_including(
              event_type: :delivery_partner_name_changed,
              delivery_partner:,
              metadata: include("name" => ['Alpha', 'A Alpha'])
            )
          )
      end
    end

    context "when the proposed name differs only by case/whitespace" do
      let(:proposed_name) { "  alpha " }

      it "returns the same instance, unchanged" do
        result = service.rename!

        expect(result).to be(delivery_partner)

        expect(result.name).to eq("Alpha")
        expect(delivery_partner.reload.name).to eq("Alpha")
      end

      it "does not enqueue a delivery_partner_name_changed event" do
        expect { service.rename! }.not_to have_enqueued_job(RecordEventJob)
      end
    end

    context "when the proposed name is blank" do
      let(:proposed_name) { "   " }

      it "adds a model error and raises ValidationError" do
        expect {
          service.rename!
        }.to raise_error(described_class::ValidationError, /Blank/)

        expect(delivery_partner.errors[:name])
          .to include("Enter the new name for #{delivery_partner.name}")

        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Event.where(event_type: "delivery_partner_name_changed")).to be_empty
      end
    end

    context "when the proposed name duplicates another delivery partner (case-insensitive)" do
      let!(:other_dp) { FactoryBot.create(:delivery_partner, name: "Taken") }
      let(:proposed_name) { " taken  " }

      it "raises ValidationError and does not change anything" do
        expect {
          expect { service.rename! }.to raise_error(described_class::ValidationError, /Duplicate/)
        }.to not_change { delivery_partner.reload.name }
         .and(not_change { Event.count })
      end
    end

    context "when the proposed name is effectively the same as current (ignore case/whitespace)" do
      let(:proposed_name) { "  alpha " }

      it "is a no-op: returns the same instance, makes no changes, and enqueues no event" do
        result = nil

        expect { result = service.rename! }
         .to not_change { delivery_partner.reload.name }
         .and(not_change { Event.count })

        expect(result).to be(delivery_partner)
        expect { service.rename! }.not_to have_enqueued_job(RecordEventJob)
      end
    end

    context "when the update raises ActiveRecord::RecordInvalid" do
      let(:proposed_name) { "Gamma" }

      before do
        allow(delivery_partner)
          .to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(delivery_partner))
      end

      it "raises and does not change the record or create an event" do
        expect { service.rename! }.to raise_error(ActiveRecord::RecordInvalid)

        expect(delivery_partner.reload.name).to eq("Alpha")
        expect(Event.where(event_type: "delivery_partner_name_changed")).to be_empty
      end
    end

    context "when event creation fails" do
      let(:proposed_name) { "Delta" }

      before do
        allow(Events::Record).to receive(:record_delivery_partner_name_changed_event!)
          .and_raise(StandardError)
      end

      it "rolls back the name change" do
        expect {
          expect { service.rename! }.to raise_error(StandardError)
        }.to not_change { delivery_partner.reload.name }
         .and(not_change { Event.count })
      end
    end
  end
end
