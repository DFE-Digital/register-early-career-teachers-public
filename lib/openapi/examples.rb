module OpenAPI
  class Examples
    class << self
      def register(endpoint:, status:, example:)
        examples[key(endpoint, status)] = example
      end

      def fetch(endpoint:, status:)
        examples[key(endpoint, status)]
      end

    private

      def examples
        @examples ||= {}
      end

      def key(endpoint, status)
        [endpoint.name, status.to_i]
      end
    end
  end
end
