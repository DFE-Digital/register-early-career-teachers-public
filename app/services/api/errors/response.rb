module API
  module Errors
    class Response
      attr_reader :error, :params

      def initialize(error:, params:)
        @params = params
        @error = error
      end

      def call
        Array(params).map do |param|
          { title: error, detail: param }
        end
      end
    end
  end
end
