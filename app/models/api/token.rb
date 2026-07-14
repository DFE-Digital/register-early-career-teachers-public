# Bearer tokens for API access granted to Lead Providers and Appropriate Bodies
# @see API::TokenManager
#
class API::Token < ApplicationRecord
  self.table_name = :api_tokens

  has_secure_token :token, length: 32
  encrypts :token, deterministic: true

  belongs_to :lead_provider, optional: true
  belongs_to :appropriate_body_period, optional: true
  belongs_to :api_third_party, class_name: "API::ThirdParty", optional: true

  has_many :api_token_deliveries, class_name: "API::TokenDelivery", dependent: :destroy, inverse_of: :api_token

  validates :lead_provider,
            presence: { message: "Lead provider must be specified" },
            unless: -> { appropriate_body_period.present? }

  validates :appropriate_body_period,
            presence: { message: "Appropriate body must be specified" },
            unless: -> { lead_provider.present? }

  validates :api_third_party,
            presence: { message: "Nominated third-party must be specified" },
            if: -> { appropriate_body_period.present? }

  validates :token, presence: { message: "Hashed token must be specified" }
  validates :token, uniqueness: { message: "Hashed token must be unique" }

  scope :lead_provider_tokens, -> { where.not(lead_provider: nil) }
  scope :appropriate_body_period_tokens, -> { where.not(appropriate_body_period: nil) }
end
