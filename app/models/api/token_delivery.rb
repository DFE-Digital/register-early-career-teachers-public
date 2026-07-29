# TODO: decide on scopes and predicates to keep
class API::TokenDelivery < ApplicationRecord
  self.table_name = :api_token_deliveries

  has_secure_token :token, length: 32
  encrypts :token, deterministic: true

  belongs_to :api_token, class_name: "API::Token", inverse_of: :api_token_deliveries

  scope :extant, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at < ?", Time.current) }

  scope :unused, -> { where(used_at: nil) }
  scope :used, -> { where.not(used_at: nil) }

  validates :expires_at, presence: true
  validates :api_token, presence: true

  validates :token, presence: { message: "Hashed token must be specified" }
  validates :token, uniqueness: { message: "Hashed token must be unique" }

  def expired? = Time.current > expires_at
  def extant? = !expired?

  def used? = used_at.present?
  def unused? = !used?
end
