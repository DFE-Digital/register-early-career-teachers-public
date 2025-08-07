module Metadata
  class Resolver
    def self.resolve_handler(object)
      class_name = object.class.name
      handler_class = "Metadata::Handlers::#{class_name}".safe_constantize

      raise ArgumentError, "No metadata handler found for #{class_name}" unless handler_class

      handler_class.new(object)
    end
  end
end
