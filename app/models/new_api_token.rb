class NewAPIToken < ApplicationRecord
  has_secure_token :hashed_token, length: 32
  encrypts :hashed_token, deterministic: true

  belongs_to :tokenable, polymorphic: true

  validates :hashed_token, presence: true, uniqueness: true

  def self.create_with_random_token!(**options)
    create!(**options).hashed_token
  end

  def self.find_by_unhashed_token(unhashed_token, tokenable_type: nil)
    query = where(hashed_token: unhashed_token)
    query = query.where(tokenable_type:) if tokenable_type.present?

    query.first
  end

  # Only used in specs and seeds
  def self.create_with_known_token!(token, **options)
    find_or_create_by!(hashed_token: token, **options)
  end
end
