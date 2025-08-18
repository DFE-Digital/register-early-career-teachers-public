module Metadata
  class Resolver
    class << self
      def resolve_handler(object)
        class_name = object.class.name
        handler_class = "Metadata::Handlers::#{class_name}".safe_constantize

        raise ArgumentError, "No metadata handler found for #{class_name}" unless handler_class

        handler_class.new(object)
      end

      def all_handlers
        Handlers
          .constants
          .map { Handlers.const_get(it) }
          .select { it.is_a?(Class) }
          .reject { it == Metadata::Handlers::Base }
      end
    end
  end
end
