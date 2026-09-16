module API::OAuth::Authorization::Revocable
  extend ActiveSupport::Concern

  def revoked? = revoked_at.present?
  def revokable? = !revoked?

  def revoke!
    touch(:revoked_at) unless revoked?
  end
end
