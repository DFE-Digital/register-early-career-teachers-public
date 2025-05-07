class APIToken < ApplicationRecord
  has_secure_token :hashed_token, length: 32
  encrypts :hashed_token, deterministic: true

  belongs_to :lead_provider

  validates :hashed_token, presence: true

  def self.create_with_random_token!(**options)
    create!(**options).hashed_token
  end

  def self.find_by_unhashed_token(unhashed_token)
    find_by(hashed_token: unhashed_token)
  end

  def self.create_with_known_token!(token, **options)
    find_or_create_by!(hashed_token: token, **options)
  end
end
