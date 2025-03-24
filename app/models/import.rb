# app/models/import.rb
class Import < ApplicationRecord
  has_one_attached :csv_file

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  # validates :csv_file, attached: true, content_type: 'text/csv'
end
