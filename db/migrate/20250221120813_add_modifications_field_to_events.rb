class AddModificationsFieldToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :modifications, :string, array: true
  end
end
