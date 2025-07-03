class RemoveNotNullFromTRSTeacherNames < ActiveRecord::Migration[8.0]
  # rubocop:disable Rails/BulkChangeTable
  def up
    remove_column :teachers, :search, :tsvector, type: :tsvector, as: "to_tsvector('unaccented', #{tsvector_columns})", stored: true
    change_column :teachers, :trs_first_name, :string, null: true
    change_column :teachers, :trs_last_name, :string, null: true
    add_column :teachers, :search, :tsvector, type: :tsvector, as: "to_tsvector('unaccented', #{tsvector_columns})", stored: true
    add_index :teachers, :search, using: :gin
  end

  def down
    remove_column :teachers, :search, :tsvector, type: :tsvector, as: "to_tsvector('unaccented', #{tsvector_columns})", stored: true
    change_column :teachers, :trs_first_name, :string, null: false, limit: 80
    change_column :teachers, :trs_last_name, :string, null: false, limit: 80
    add_column :teachers, :search, :tsvector, type: :tsvector, as: "to_tsvector('unaccented', #{tsvector_columns})", stored: true
    add_index :teachers, :search, using: :gin
  end

  def tsvector_columns
    %w[trs_first_name trs_last_name corrected_name].map { |col| "coalesce(#{col}, '')" }.join(" || ' ' || ")
  end
  # rubocop:enable Rails/BulkChangeTable
end
