class AllowNullEstablishmentNumberInGIASSchools < ActiveRecord::Migration[8.0]
  def change
    change_column_null :gias_schools, :establishment_number, true
  end
end
