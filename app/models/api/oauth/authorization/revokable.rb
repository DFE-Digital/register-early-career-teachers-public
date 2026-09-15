module API::OAuth::Authorization::Revokable
  extend ActiveSupport::Concern

  def revoked? = revoked_at.present?

  def revoke!
    update!(revoked_at: Time.zone.now)
  end
end
