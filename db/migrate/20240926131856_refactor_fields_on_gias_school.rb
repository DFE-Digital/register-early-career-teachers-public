class RefactorFieldsOnGIASSchool < ActiveRecord::Migration[7.2]
  def change
    change_table :gias_schools do |t|
      t.remove :administrative_district_code, type: :string, null: false
      t.remove :phase_code, type: :integer, null: false
      t.remove :type_code, type: :integer, null: false
      t.remove :induction_eligibility, type: :enum, enum_type: :induction_eligibility_status, null: false
      t.remove :easting, type: :string, null: false
      t.remove :northing, type: :string, null: false

      t.change_null(:type_name, false)
      t.boolean :induction_eligibility, null: false
      t.boolean :in_england, null: false
      t.remove_index :name, name: "index_gias_schools_on_name"
      t.index :name, name: "index_gias_schools_on_name"
    end

    change_column_null(:gias_school_links, :link_date, true)
    drop_enum :induction_eligibility_status, %w[eligible ineligible]
    remove_foreign_key :gias_school_links, :gias_schools, column: :link_urn, primary_key: :urn, if_exists: true
  end
end
