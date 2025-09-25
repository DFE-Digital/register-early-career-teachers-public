class User < ApplicationRecord
  Role = Data.define(:identifier, :name)

  ROLES = [
    Role.new(identifier: :admin, name: 'Admin'),
    Role.new(identifier: :super_admin, name: 'Super admin'),
    Role.new(identifier: :finance, name: 'Finance'),
  ].freeze

  enum :role, ROLES.to_h { |r| [r.identifier, r.identifier.to_s] }, validate: { message: 'Must be admin, finance or super_admin' }

  encrypts :otp_secret

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, notify_email: true
  validates :role, presence: true

  # Associations
  has_many :events
  has_many :authored_events, class_name: 'Event', inverse_of: :author
end
