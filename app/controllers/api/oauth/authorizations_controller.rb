module API
  module OAuth
    class AuthorizationsController < ::AppropriateBodiesController
      def new
        @authorization_request = AuthorizationRequest.build(authorization_request_params)
        return render(:invalid_request, status: :bad_request) unless @authorization_request.redirectable?

        if @authorization_request.valid?
          @authorization_request.store_in(session)
        else
          AuthorizationRequest.clear_from(session)
          redirect_to(
            @authorization_request.redirect_uri_with_params,
            allow_other_host: true
          )
        end
      end

      def create
        @authorization_request = AuthorizationRequest.from(session)
        render json: @authorization_request
      end

      def destroy
        @authorization_request = AuthorizationRequest.from(session)
        return render(:invalid_request, status: :bad_request) unless @authorization_request&.redirectable?

        AuthorizationRequest.clear_from(session)
        redirect_to(
          @authorization_request.redirect_uri_with_params(
            error: :access_denied, error_description: "User refused connection"
          ),
          allow_other_host: true
        )
      end

    private

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
