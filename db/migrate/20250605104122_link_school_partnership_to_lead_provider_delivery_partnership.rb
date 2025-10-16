class LinkSchoolPartnershipToLeadProviderDeliveryPartnership < ActiveRecord::Migration[8.0]
  def change
    # NOTE: we won't have any school partnerships in prod but we might in staging/sandbox so
    #       we'll have to delete them before re-seeding
    add_reference :school_partnerships, :lead_provider_delivery_partnership, index: true, null: false
  end
end
