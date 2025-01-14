class TeacherMigrationFailure < ApplicationRecord
  belongs_to :teacher

  validates :message, presence: true

  def migration_item
    if migration_item_id.present?
      begin
        migration_item_type.constantize.find_by(id: migration_item_id)
      rescue StandardError
        Rails.logger.error("Error instantiating migration item for id #{migration_item_id}")
      end
    end
  end
end
