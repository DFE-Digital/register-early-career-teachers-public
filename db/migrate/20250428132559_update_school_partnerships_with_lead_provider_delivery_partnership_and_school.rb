class UpdateSchoolPartnershipsWithLeadProviderDeliveryPartnershipAndSchool < ActiveRecord::Migration[8.0]
  def change
    change_table :school_partnerships do |t|
      t.references :lead_provider_delivery_partnership, null: false, foreign_key: true # rubocop:disable Rails/NotNullColumn
      t.references :school, null: false, foreign_key: true # rubocop:disable Rails/NotNullColumn
    end
  end
end
