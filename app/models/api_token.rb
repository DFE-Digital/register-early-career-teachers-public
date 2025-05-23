class APIToken < ApplicationRecord
  has_secure_token :token, length: 32
  encrypts :token, deterministic: true

  belongs_to :lead_provider

  validates :lead_provider, presence: { message: "Lead provider must be specified" }
  validates :token, presence: { message: "Hashed token must be specified" }
  validates :token, uniqueness: { message: "Hashed token must be unique" }
end
