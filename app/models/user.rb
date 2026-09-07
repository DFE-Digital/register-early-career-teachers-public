class User < ApplicationRecord
  VALID_EMAIL_SUFFIX = "@education.gov.uk"

  ROLES = {
    admin: "Admin",
    user_manager: "User manager",
    finance: "Finance",
    product_team: "Product team",
  }.freeze

  enum :role, ROLES.keys.index_with(&:to_s), validate: { message: "Must be admin, finance, user_manager or product_team" }

  encrypts :otp_secret

  # Validations
  validates :name, presence: { message: "Enter a name" }
  validates :role, presence: { message: "Choose a role" }
  validates :email,
            presence: { message: "Enter an email address" },
            uniqueness: { message: "Email address already used, enter another" },
            notify_email: true
  validate :ensure_email_belongs_to_dfe, if: -> { email.present? }

  # Associations
  has_many :events
  has_many :authored_events, class_name: "Event", inverse_of: :author

  # Scopes
  scope :alphabetical, -> { order(name: :asc) }

  def super_admin?
    user_manager?
  end

  def can_manage_users?
    user_manager? || finance? || product_team?
  end

  def finance_access?
    finance? || product_team?
  end

private

  def ensure_email_belongs_to_dfe
    return if email.downcase.ends_with?(VALID_EMAIL_SUFFIX)

    errors.add(:email, %(Enter an '@education.gov.uk' email address))
  end
end
