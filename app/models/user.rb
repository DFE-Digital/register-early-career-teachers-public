class User < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, notify_email: true

  # TODO: we can encrypt the secret in the DB but we need to set up keys first
  # encrypts :otp_secret

  # Associations
  has_many :dfe_roles
  has_many :events
  has_many :authored_events, class_name: 'Event', inverse_of: :author

  # Instance Methods
  def dfe_user?
    dfe_roles.any?
  end
end
