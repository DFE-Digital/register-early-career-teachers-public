RSpec.describe DeliveryPartners::UpdateLeadProviderPairings do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
  let!(:lead_provider_3) { FactoryBot.create(:lead_provider, name: "Lead Provider 3") }

  let!(:framework_agreement_1) { FactoryBot.create(:framework_agreement, lead_provider: lead_provider_1, contract_period:) }
  let!(:framework_agreement_2) { FactoryBot.create(:framework_agreement, lead_provider: lead_provider_2, contract_period:) }
  let!(:framework_agreement_3) { FactoryBot.create(:framework_agreement, lead_provider: lead_provider_3, contract_period:) }

  let(:service) do
    described_class.new(
      delivery_partner:,
      contract_period:,
      framework_agreement_ids: new_framework_agreement_ids,
      author:
    )
  end

  describe "#update!" do
    context "when adding new partnerships" do
      let(:new_framework_agreement_ids) { [framework_agreement_1.id, framework_agreement_2.id] }

      it "creates new lead provider delivery partnerships and records an event for each" do
        expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(2)

        partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
        expect(partnerships.map(&:framework_agreement_id)).to contain_exactly(framework_agreement_1.id, framework_agreement_2.id)

        events = Event.where(event_type: "lead_provider_delivery_partnership_added")
        expect(events.count).to eq(2)
        expect(events.map(&:lead_provider_delivery_partnership_id)).to match_array(partnerships.map(&:id))
      end

      it "returns true on success" do
        expect(service.update!).to be true
      end
    end

    context "when working with existing partnerships" do
      let!(:existing_partnership_1) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          delivery_partner:,
          framework_agreement: framework_agreement_1
        )
      end

      context "when keeping existing and adding new partnerships" do
        let(:new_framework_agreement_ids) { [framework_agreement_1.id, framework_agreement_2.id, framework_agreement_3.id] }

        it "keeps existing partnerships and adds new ones" do
          expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(2)

          partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
          expect(partnerships.map(&:framework_agreement_id)).to contain_exactly(
            framework_agreement_1.id, # existing - kept because it's in the submitted list
            framework_agreement_2.id, # new - added
            framework_agreement_3.id  # new - added
          )
        end
      end

      context "when replacing existing partnerships with new ones" do
        let(:new_framework_agreement_ids) { [framework_agreement_2.id, framework_agreement_3.id] }

        it "removes existing partnerships, adds new ones and records an event for each" do
          expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(1) # -1 + 2 = 1

          partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
          expect(partnerships.map(&:framework_agreement_id)).to contain_exactly(
            framework_agreement_2.id,
            framework_agreement_3.id
          )

          expect(Event.where(event_type: "lead_provider_delivery_partnership_removed").count).to eq(1)
          expect(Event.where(event_type: "lead_provider_delivery_partnership_added").count).to eq(2)
        end
      end
    end

    context "when removing existing partnerships" do
      let!(:existing_partnership_1) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          delivery_partner:,
          framework_agreement: framework_agreement_1
        )
      end

      let!(:existing_partnership_2) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          delivery_partner:,
          framework_agreement: framework_agreement_2
        )
      end

      context "when unchecking some partnerships" do
        let(:new_framework_agreement_ids) { [framework_agreement_1.id] }

        it "removes unchecked partnerships and records a removal event" do
          removed_lead_provider = existing_partnership_2.lead_provider

          expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(-1)

          partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
          expect(partnerships.map(&:framework_agreement_id)).to contain_exactly(framework_agreement_1.id)

          event = Event.where(event_type: "lead_provider_delivery_partnership_removed").sole
          expect(event).to have_attributes(
            delivery_partner_id: delivery_partner.id,
            lead_provider_id: removed_lead_provider.id
          )
        end
      end

      context "when unchecking all partnerships" do
        let(:new_framework_agreement_ids) { [] }

        it "removes all partnerships and records an event for each" do
          expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(-2)

          partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
          expect(partnerships).to be_empty
          expect(Event.where(event_type: "lead_provider_delivery_partnership_removed").count).to eq(2)
        end
      end

      context "when adding and removing partnerships in the same operation" do
        let(:new_framework_agreement_ids) { [framework_agreement_2.id, framework_agreement_3.id] }

        it "removes unchecked partnerships, adds new ones and records an event for each" do
          expect { service.update! }.not_to change(LeadProviderDeliveryPartnership, :count) # -1 + 1 = 0

          partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
          expect(partnerships.map(&:framework_agreement_id)).to contain_exactly(
            framework_agreement_2.id,
            framework_agreement_3.id
          )

          expect(Event.where(event_type: "lead_provider_delivery_partnership_removed").count).to eq(1)
          expect(Event.where(event_type: "lead_provider_delivery_partnership_added").count).to eq(1)
        end
      end
    end

    context "when no new partnerships to add" do
      let!(:existing_partnership_1) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          delivery_partner:,
          framework_agreement: framework_agreement_1
        )
      end

      let(:new_framework_agreement_ids) { [framework_agreement_1.id] }

      it "does not change partnerships or record any events" do
        expect { service.update! }.not_to change(LeadProviderDeliveryPartnership, :count)
        expect(Event.count).to eq(0)
      end

      it "returns true" do
        expect(service.update!).to be true
      end
    end

    context "when there is a database error" do
      let(:new_framework_agreement_ids) { [framework_agreement_1.id] }

      before do
        create_service = instance_double(LeadProviderDeliveryPartnerships::Create)
        allow(LeadProviderDeliveryPartnerships::Create).to receive(:new).and_return(create_service)
        allow(create_service).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(LeadProviderDeliveryPartnership.new))
      end

      it "returns false on error" do
        expect(service.update!).to be false
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to update lead provider pairings/)
        service.update!
      end
    end
  end
end
