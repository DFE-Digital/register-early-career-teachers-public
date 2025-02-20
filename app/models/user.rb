class User < ApplicationRecord
  encrypts :otp_secret

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, notify_email: true

  # Associations
  has_many :dfe_roles
  has_many :events
  has_many :authored_events, class_name: 'Event', inverse_of: :author

  # Instance Methods
  def dfe_user?
    dfe_roles.any?
  end
end
