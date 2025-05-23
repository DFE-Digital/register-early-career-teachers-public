module API
  module Paginatable
    extend ActiveSupport::Concern
    include Pagy::Backend

    included do
      rescue_from Pagy::VariableError, with: :invalid_pagination_response
    end

  private

    def paginate(scope)
      _pagy, paginated_records = pagy_countless(scope, limit: per_page, page:)

      paginated_records
    end

    def per_page
      [page_params.dig(:page, :per_page).to_i.nonzero? || Pagy::DEFAULT[:api_per_page], Pagy::DEFAULT[:api_max_per_page]].min
    end

    def page
      page_params.dig(:page, :page).to_i.nonzero? || 1
    end

    def page_params
      params.permit(page: %i[per_page page])
    end

    def invalid_pagination_response(_exception)
      render json: { error: "Bad request" }.to_json, status: :bad_request

      # render json: {
      #   errors: API::Errors::Response.new(
      #     error: "Bad request",
      #     params: "The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number"
      #   ).call
      # }, status: :bad_request
    end
  end
end
