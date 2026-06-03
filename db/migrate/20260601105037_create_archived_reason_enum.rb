class CreateArchivedReasonEnum < ActiveRecord::Migration[8.1]
  def change
    create_enum :archived_reasons, %w[registered_in_error]
  end
end
