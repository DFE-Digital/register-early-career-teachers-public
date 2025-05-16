class APIToken < ApplicationRecord
  has_secure_token :hashed_token, length: 32
  encrypts :hashed_token, deterministic: true

  belongs_to :lead_provider, optional: true

  enum :scope, {
    lead_provider: "lead_provider",
    teacher_record_service: "teacher_record_service",
  }, validate: true

  validates :hashed_token, presence: true
  validates :scope, presence: true
  validates :lead_provider, presence: true, if: -> { scope == APIToken.scopes[:lead_provider] }

  def self.create_with_random_token!(**options)
    create!(**options).hashed_token
  end

  def self.find_by_unhashed_token(unhashed_token, scope:)
    find_by(hashed_token: unhashed_token, scope:)
  end

  def self.create_with_known_token!(token, scope: scopes[:lead_provider], **options)
    find_or_create_by!(hashed_token: token, scope:, **options)
  end
end
