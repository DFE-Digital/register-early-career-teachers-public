module API
  module Paginatable
    extend ActiveSupport::Concern
    include Pagy::Backend

  private

    def paginate(scope)
      _pagy, paginated_records = pagy_countless(scope, limit: per_page, page:)

      paginated_records
    rescue Pagy::VariableError
      raise_as_bad_request!
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

    def raise_as_bad_request!
      raise ActionController::BadRequest, "The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number"
    end
  end
end
