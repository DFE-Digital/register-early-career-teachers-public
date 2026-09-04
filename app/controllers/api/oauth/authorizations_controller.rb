module API
  module OAuth
    class AuthorizationsController < ::AppropriateBodiesController
      def new
        @authorization_request = build_authorization_request
        return render(:invalid_request, status: :bad_request) unless @authorization_request.redirectable?

        if @authorization_request.valid?
          store_authorization_request
          @client = @authorization_request.client
        else
          destroy_authorization_request
          redirect_to(
            @authorization_request.redirect_uri_with_params,
            allow_other_host: true
          )
        end
      end

      def create
        head :not_implemented
      end

      def destroy
        @authorization_request = resume_authorization_request
        return render(:invalid_request, status: :bad_request) unless @authorization_request&.redirectable?

        destroy_authorization_request

        redirect_to(
          @authorization_request.redirect_uri_with_params(error: :access_denied, error_description: "User refused connection"),
          allow_other_host: true
        )
      end

    private

      def build_authorization_request
        AuthorizationRequest.new(
          logged_in_appropriate_body_period_id: @appropriate_body.id,
          **authorization_request_params
        )
      end

      def resume_authorization_request
        return if session[:oauth_authorization_request].blank?

        AuthorizationRequest.new(**session[:oauth_authorization_request].symbolize_keys)
      end

      def store_authorization_request
        session[:oauth_authorization_request] = @authorization_request.attributes
      end

      def destroy_authorization_request
        session.delete(:oauth_authorization_request)
      end

      def authorization_request_params
        params.permit(:response_type, :client_id, :appropriate_body_period_id, :redirect_uri,
                      :code_challenge, :code_challenge_method, :state).to_h.symbolize_keys
      end
    end
  end
end
