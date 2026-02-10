class CreateLeadSchoolPeriod < ActiveRecord::Migration[8.0]
  def change
    create_table :lead_school_periods do |t|
      t.references :school, foreign_key: true
      t.references :appropriate_body, foreign_key: true
      t.date :started_on, null: false
      t.date :finished_on
      t.virtual :range, type: :daterange, as: "daterange(started_on, finished_on)", stored: true

      t.timestamps
    end
  end
end
