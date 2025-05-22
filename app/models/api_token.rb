class APIToken < ApplicationRecord
  has_secure_token :token, length: 32
  encrypts :token, deterministic: true

  belongs_to :lead_provider

  validates :lead_provider, presence: { message: "Lead provider must be specified" }
  validates :token, presence: { message: "Hashed token must be specified" }
  validates :token, uniqueness: { message: "Hashed token must be unique" }

  scope :lead_provider_tokens, -> { where.not(lead_provider: nil) }

  class << self
    def create_lead_provider_api_token!(lead_provider:, token: nil, description: nil)
      description = "A lead provider token for #{lead_provider.name}" if description.nil?

      create!(
        lead_provider:,
        token:,
        description:
      )
    end

    def find_lead_provider_api_token(token:)
      find_by(token:).tap { |api_token| api_token&.touch(:last_used_at) }
    end
  end
end
