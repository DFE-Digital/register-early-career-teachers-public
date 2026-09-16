RSpec.describe SchoolPartnerships::Update do
  let!(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: school_partnership.framework_agreement) }

  let(:service) do
    described_class.new(
      school_partnership:,
      lead_provider_delivery_partnership:
    )
  end

  describe "#update" do
    subject(:update_school_partnership) { service.update }

    it "updates the delivery partner of the school partnership" do
      updated_school_partnership = nil

      expect { updated_school_partnership = service.update }.to(change { school_partnership.reload.attributes })

      expect(updated_school_partnership).to have_attributes(lead_provider_delivery_partnership:)
    end

    it "records a school partnership updated event" do
      previous_delivery_partner = school_partnership.delivery_partner
      school_partnership = update_school_partnership

      event = Event.where(event_type: "school_partnership_updated").sole
      expect(event).to have_attributes(
        school_partnership_id: school_partnership.id,
        delivery_partner_id: school_partnership.delivery_partner.id,
        lead_provider_id: school_partnership.lead_provider.id
      )
      expect(event.heading).to include(previous_delivery_partner.name, school_partnership.delivery_partner.name)
    end
  end
end
