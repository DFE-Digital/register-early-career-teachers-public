module API::OAuth::Authorizations
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :authorization_request
    attribute :author

    def call
      ActiveRecord::Base.transaction do
        authorization = authorization_request.build_authorization
        authorization.granted_by_name = author.name
        authorization.granted_by_dfe_sign_in_user_id = author.dfe_sign_in_user_id
        Events::Record.record_oauth_authorization_created_event!(author:, authorization:) if authorization.save
        authorization
      end
    end
  end
end
