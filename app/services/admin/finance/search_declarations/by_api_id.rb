module Admin
  module Finance
    module SearchDeclarations
      class ByAPIId
        def initialize(raw_query:)
          @raw_query = raw_query
        end

        def call
          normalised_query = normalised_api_id(@raw_query)
          return nil if normalised_query.blank?

          Declaration.find_by(api_id: normalised_query)
        end

      private

        def normalised_api_id(raw_query)
          raw_string = raw_query.to_s
          stripped_string = raw_string.strip
          uuid_safe_string = stripped_string.gsub(/[^0-9a-f-]/i, "")
          uuid_safe_string.downcase
        end
      end
    end
  end
end
