RSpec.describe SchoolPartnerships::Update do
  let!(:school_partnership) { FactoryBot.create(:school_partnership) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: school_partnership.active_lead_provider) }

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
      allow(Events::Record).to receive(:record_school_partnership_updated_event!).once.and_call_original

      previous_delivery_partner = school_partnership.delivery_partner
      school_partnership = update_school_partnership

      expect(Events::Record).to have_received(:record_school_partnership_updated_event!).once.with(
        hash_including(
          {
            school_partnership:,
            author: kind_of(Events::LeadProviderAPIAuthor),
            previous_delivery_partner:,
            modifications: school_partnership.saved_changes
          }
        )
      )
    end
  end
end
