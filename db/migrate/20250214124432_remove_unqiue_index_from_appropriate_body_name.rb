class RemoveUnqiueIndexFromAppropriateBodyName < ActiveRecord::Migration[8.0]
  def change
    remove_index :appropriate_bodies, column: 'name', name: "index_appropriate_bodies_on_name", unique: true
  end
end
