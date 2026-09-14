module API::OAuth::Authorizations
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :authorization_request
    attribute :author

    def call
      ActiveRecord::Base.transaction do
        authorization = authorization_request.build_authorization
        Events::Record.record_oauth_authorization_created_event!(author:, authorization:) if authorization.save
        authorization
      end
    end
  end
end
