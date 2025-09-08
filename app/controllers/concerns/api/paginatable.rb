module API
  module Paginatable
    extend ActiveSupport::Concern
    include Pagy::Backend

  private

    def paginate(scope)
      _pagy, paginated_records = pagy(scope, limit: per_page, page:)

      paginated_records
    rescue Pagy::VariableError
      raise_as_bad_request!
    end

    def per_page
      [params.dig(:page, :per_page)&.to_i || Pagy::DEFAULT[:api_per_page], Pagy::DEFAULT[:api_max_per_page]].min
    end

    def page
      params.dig(:page, :page)&.to_i || 1
    end

    def raise_as_bad_request!
      raise ActionController::BadRequest, "The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number"
    end
  end
end
