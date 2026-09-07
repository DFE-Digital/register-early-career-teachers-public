class RenameDeclarationDateToEvidencedAt < ActiveRecord::Migration[8.1]
  def change
    rename_column :declarations, :declaration_date, :evidenced_at
  end
end
