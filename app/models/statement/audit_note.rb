class Statement::AuditNote < ApplicationRecord
  belongs_to :statement

  validates :body, presence: { message: "Enter the audit note text" }
end
