class RemoveSparsityUpliftAndPupilPremiumUpliftFromTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.remove :pupil_premium_uplift, type: :boolean
      t.remove :sparsity_uplift, type: :boolean
    end
  end
end
