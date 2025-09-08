module Metadata
  class Manager
    def refresh_metadata!(objects)
      return if Thread.current[:skip_metadata_updates]

      Array.wrap(objects).each { resolve_handler(it).refresh_metadata! }
    end

    class << self
      def refresh_all_metadata!(async: false)
        return if Thread.current[:skip_metadata_updates]

        Resolver.all_handlers.each { it.refresh_all_metadata!(async:) }
      end

      def destroy_all_metadata!
        return if Thread.current[:skip_metadata_updates]

        Resolver.all_handlers.each(&:destroy_all_metadata!)
      end

      def skip_metadata_updates
        previous = Thread.current[:skip_metadata_updates]
        Thread.current[:skip_metadata_updates] = true
        yield
      ensure
        Thread.current[:skip_metadata_updates] = previous
      end
    end

  private

    def resolve_handler(object)
      Resolver.resolve_handler(object)
    end
  end
end
