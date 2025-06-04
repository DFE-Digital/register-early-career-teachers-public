module API
  module DateFilterable
    extend ActiveSupport::Concern

  protected

    def updated_since
      parse_date_filter(filter_name: :updated_since)
    end

  private

    def parse_date_filter(filter_name:)
      date_param = params.dig(:filter, filter_name)

      return if date_param.blank?

      Time.iso8601(URI.decode_www_form_component(date_param))
    rescue ArgumentError
      raise ActionController::BadRequest, "The filter '#/#{filter_name}' must be a valid ISO 8601 date"
    end
  end
end
