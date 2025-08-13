module Metadata
  class Manager
    def refresh_metadata!(objects)
      Array.wrap(objects).each { resolve_handler(it).refresh_metadata! }
    end

    class << self
      def refresh_all_metadata!(async: false)
        Resolver.all_handlers.each { it.refresh_all_metadata!(async:) }
      end
    end

  private

    def resolve_handler(object)
      Resolver.resolve_handler(object)
    end
  end
end
