class AddDeclarationToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :declaration, index: true, null: true, foreign_key: { on_delete: :nullify }
  end
end
