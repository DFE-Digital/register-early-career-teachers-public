module API
  module Errors
    class Response
      attr_reader :title, :messages

      def initialize(title:, messages:)
        @title = title
        @messages = Array(messages).uniq
      end

      def call
        messages.map { |detail| mapper.map_error(title:, detail:).freeze }
      end

      def self.from(service)
        {
          errors: service.errors.messages.flat_map do |title, messages|
            new(title:, messages:).call
          end
        }
      end

    private

      def mapper
        @mapper ||= API::Errors::Mapper.new
      end
    end
  end
end
