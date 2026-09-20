class CreateRegionAwards < ActiveRecord::Migration[8.1]
  def change
    create_table :region_awards do |t|
      t.references :appropriate_body_period, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.datetime :deactivated_at, null: true
      t.string :deactivation_reason

      t.timestamps
    end

    # One active award per region within an appropriate body
    add_index :region_awards,
              %i[appropriate_body_period_id region_id],
              unique: true,
              where: "deactivated_at IS NULL",
              name: "index_region_awards_on_appropriate_body_period_and_region"

    # A region can only be actively awarded once at a time
    add_index :region_awards,
              :region_id,
              unique: true,
              where: "deactivated_at IS NULL",
              name: "index_region_awards_on_active_region"
  end
end
