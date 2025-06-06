class LinkSchoolPartnershipToAvailableProviderPairing < ActiveRecord::Migration[8.0]
  def change
    # NOTE: we won't have any school partnerships in prod but we might in staging/sandbox so
    #       we'll have to delete them before re-seeding
    # rubocop:disable Rails/NotNullColumn
    add_reference :school_partnerships, :available_provider_pairing, index: true, null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
