class User < ApplicationRecord
  ROLES = {
    admin: "Admin",
    user_manager: "User manager",
    finance: "Finance",
  }.freeze

  enum :role, ROLES.keys.index_with(&:to_s), validate: { message: "Must be admin, finance or super_admin" }

  encrypts :otp_secret

  # Validations
  validates :name, presence: { message: "Enter a name" }
  validates :role, presence: { message: "Choose a role" }
  validates :email,
            presence: { message: "Enter an email address" },
            uniqueness: { message: "Email address already used, enter another" },
            notify_email: true

  # Associations
  has_many :events
  has_many :authored_events, class_name: "Event", inverse_of: :author

  # Scopes
  scope :alphabetical, -> { order(name: :asc) }

  def super_admin?
    user_manager?
  end

  def can_manage_users?
    user_manager? || finance?
  end

  def finance_access?
    finance?
  end
end
