class API::Token < ApplicationRecord
  self.table_name = :api_tokens

  has_secure_token :token, length: 32
  encrypts :token, deterministic: true

  belongs_to :lead_provider

  validates :lead_provider, presence: { message: "Lead provider must be specified" }
  validates :token, presence: { message: "Hashed token must be specified" }
  validates :token, uniqueness: { message: "Hashed token must be unique" }

  scope :lead_provider_tokens, -> { where.not(lead_provider: nil) }
end
