module API::OAuth::Authorization::Revokable
  extend ActiveSupport::Concern

  included do
    scope :revoked, -> { where.not(revoked_at: nil) }
    scope :unrevoked, -> { where(revoked_at: nil) }
  end

  def revoked? = revoked_at.present?

  def revoke!
    update!(revoked_at: Time.zone.now)
  end
end
