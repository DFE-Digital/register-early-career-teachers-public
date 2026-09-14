module API
  module OAuth
    class AuthorizationsController < ::AppropriateBodiesController
      before_action :build_authorization_request, only: :new
      before_action :resume_authorization_request, only: %i[create destroy]
      before_action :stop_unless_redirectable

      def new
        if @authorization_request.valid?
          @authorization_request.store_in(session)
        else
          AuthorizationRequest.clear_from(session)
          redirect_to(
            @authorization_request.unsuccessful_redirect_uri,
            allow_other_host: true
          )
        end
      end

      def create
        @authorization = Authorizations::Create.new(authorization_request: @authorization_request, author: current_user).call

        if @authorization.persisted?
          AuthorizationRequest.clear_from(session)
          redirect_to(
            @authorization_request.successful_redirect_uri(code: @authorization.code),
            allow_other_host: true
          )
        else
          redirect_to(
            @authorization_request.unsuccessful_redirect_uri(
              error: :invalid_request,
              error_description: @authorization.error_messages_description
            ),
            allow_other_host: true
          )
        end
      end

      def destroy
        AuthorizationRequest.clear_from(session)
        redirect_to(
          @authorization_request.unsuccessful_redirect_uri(
            error: :access_denied, error_description: "User refused connection"
          ),
          allow_other_host: true
        )
      end

    private

      def build_authorization_request
        @authorization_request = AuthorizationRequest.build(authorization_request_params)
      end

      def resume_authorization_request
        @authorization_request = AuthorizationRequest.from(session)
      end

      def stop_unless_redirectable
        render(:invalid_request, status: :bad_request) unless @authorization_request&.redirectable?
      end

      def authorization_request_params
        params.permit(
          :response_type, :client_id, :appropriate_body_period_id, :redirect_uri,
          :code_challenge, :code_challenge_method, :state
        )
          .to_h
          .symbolize_keys
          .merge(logged_in_appropriate_body_period_id: @appropriate_body.id)
      end
    end
  end
end
