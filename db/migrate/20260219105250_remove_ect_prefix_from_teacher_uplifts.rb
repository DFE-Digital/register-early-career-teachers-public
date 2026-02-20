class RemoveECTPrefixFromTeacherUplifts < ActiveRecord::Migration[8.0]
  def change
    rename_column :teachers, :ect_pupil_premium_uplift, :pupil_premium_uplift
    rename_column :teachers, :ect_sparsity_uplift, :sparsity_uplift
  end
end
