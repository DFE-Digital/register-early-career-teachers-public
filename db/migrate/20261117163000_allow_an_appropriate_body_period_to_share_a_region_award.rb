class AllowAnAppropriateBodyPeriodToShareARegionAward < ActiveRecord::Migration[8.1]
  # Star Teaching School Hub has been found to be an edge case and this database constraint
  # prevents them operating two concurrent periods with the same three regions and lead schools
  # but flipping the provisioner.
  #
  # One school has acted as AB for most of the cases across the three regions since Sep 2021.
  #
  # One school has acted as AB for x13 cases across the same three regions since Sep 2021,
  # in cases where the other school was statutorily not permitted to act as the AB.
  #
  # A region is still led by one school at a time; that is enforced on the model.
  def up
    remove_index :region_awards, name: "index_region_awards_on_active_region"
  end

  def down
    add_index :region_awards,
              :region_id,
              unique: true,
              where: "(deactivated_at IS NULL)",
              name: "index_region_awards_on_active_region"
  end
end
