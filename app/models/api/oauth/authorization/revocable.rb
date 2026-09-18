module API::OAuth::Authorization::Revocable
  extend ActiveSupport::Concern

  included do
    scope :revoked, -> { where.not(revoked_at: nil) }
    scope :not_revoked, -> { where(revoked_at: nil) }
  end

  def revoked? = revoked_at.present?
  def not_revoked? = !revoked?

  def revoke!
    touch(:revoked_at) unless revoked?
  end
end
