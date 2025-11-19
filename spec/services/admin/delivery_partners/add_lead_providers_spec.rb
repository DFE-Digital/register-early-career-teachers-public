RSpec.describe Admin::DeliveryPartners::AddLeadProviders do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:year) { contract_period.year }

  let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }

  let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
  let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

  let(:service) do
    described_class.new(
      delivery_partner_id: delivery_partner.id,
      year:,
      lead_provider_ids:,
      author:
    )
  end

  describe "#call" do
    context "when all parameters are valid" do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s, active_lead_provider_2.id.to_s] }

      it "executes successfully without raising an exception" do
        expect { service.call }.not_to raise_error
      end

      it "creates lead provider delivery partnerships" do
        expect { service.call }.to change(LeadProviderDeliveryPartnership, :count).by(2)
      end

      it "calls the appropriate service based on contract period" do
        # Since the default factory creates a current contract period (2025 starting June 1, 2025)
        # and current date is after June 1, 2025, it should call AddLeadProviderPairings (add-to-existing mode)
        expect(DeliveryPartners::AddLeadProviderPairings).to receive(:new).with(
          delivery_partner:,
          contract_period:,
          active_lead_provider_ids: [active_lead_provider_1.id, active_lead_provider_2.id],
          author:
        ).and_call_original

        service.call
      end
    end

    context "when contract period is in the future" do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2026, started_on: 1.year.from_now, finished_on: 2.years.from_now) }
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s, active_lead_provider_2.id.to_s] }

      it "calls UpdateLeadProviderPairings" do
        expect(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).with(
          delivery_partner:,
          contract_period:,
          active_lead_provider_ids: [active_lead_provider_1.id, active_lead_provider_2.id],
          author:
        ).and_call_original

        service.call
      end
    end

    context "when delivery partner does not exist" do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }

      before do
        delivery_partner.lead_provider_metadata.destroy_all
        delivery_partner.destroy!
      end

      it "raises a ValidationError" do
        expect { service.call }.to raise_error(described_class::ValidationError, "Delivery partner not found")
      end
    end

    context "when contract period does not exist" do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }
      let(:year) { 2099 }

      it "raises a ValidationError" do
        expect { service.call }.to raise_error(described_class::ValidationError, "Contract period for year 2099 not found")
      end
    end

    context "when lead provider IDs are empty" do
      let(:lead_provider_ids) { [] }

      context "for current or past contract periods" do
        let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, started_on: 1.year.ago, finished_on: 1.month.from_now) }

        it "raises a NoLeadProvidersSelectedError" do
          expect { service.call }.to raise_error(described_class::NoLeadProvidersSelectedError, "Select at least one lead provider")
        end
      end

      context "for future contract periods" do
        let(:contract_period) { FactoryBot.create(:contract_period, year: 2026, started_on: 1.year.from_now, finished_on: 2.years.from_now) }

        it "allows empty selections and succeeds" do
          expect { service.call }.not_to raise_error
        end

        it "removes all existing partnerships" do
          # Create an existing partnership first
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            delivery_partner:,
            active_lead_provider: active_lead_provider_1
          )

          expect { service.call }.to change(LeadProviderDeliveryPartnership, :count).by(-1)
        end
      end
    end

    context "when lead provider IDs contain blank values" do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s, "", "   ", active_lead_provider_2.id.to_s] }

      it "filters out blank values and succeeds" do
        expect { service.call }.not_to raise_error
      end

      it "creates partnerships only for non-blank IDs" do
        expect { service.call }.to change(LeadProviderDeliveryPartnership, :count).by(2)
      end
    end

    context "when lead provider IDs only contain blank values" do
      let(:lead_provider_ids) { ["", "   ", nil] }

      context "for current or past contract periods" do
        let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, started_on: 1.year.ago, finished_on: 1.month.from_now) }

        it "raises a NoLeadProvidersSelectedError" do
          expect { service.call }.to raise_error(described_class::NoLeadProvidersSelectedError, "Select at least one lead provider")
        end
      end

      context "for future contract periods" do
        let(:contract_period) { FactoryBot.create(:contract_period, year: 2026, started_on: 1.year.from_now, finished_on: 2.years.from_now) }

        it "allows empty selections and succeeds" do
          expect { service.call }.not_to raise_error
        end
      end
    end

    context "when the partnership service fails" do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }

      before do
        add_service_double = instance_double(DeliveryPartners::AddLeadProviderPairings)
        allow(DeliveryPartners::AddLeadProviderPairings).to receive(:new).and_return(add_service_double)
        allow(add_service_double).to receive(:add!).and_return(false)
      end

      it "raises a ValidationError" do
        expect { service.call }.to raise_error(described_class::ValidationError, "Unable to update lead provider partners")
      end
    end

    context "when an unexpected error occurs" do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }

      before do
        add_service_double = instance_double(DeliveryPartners::AddLeadProviderPairings)
        allow(DeliveryPartners::AddLeadProviderPairings).to receive(:new).and_return(add_service_double)
        allow(add_service_double).to receive(:add!).and_raise(StandardError, "Something went wrong")
      end

      it "lets the exception bubble up" do
        expect { service.call }.to raise_error(StandardError, "Something went wrong")
      end
    end
  end
end
