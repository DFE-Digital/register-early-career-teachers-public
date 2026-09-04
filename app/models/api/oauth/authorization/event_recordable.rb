module API::OAuth::Authorization::EventRecordable
  extend ActiveSupport::Concern

  included do
    attribute :author, default: -> { Current.user }

    after_create_commit :record_created_event
  end

private

  def record_created_event
    Events::Record.record_oauth_authorization_created_event!(author:, authorization: self)
  end
end
