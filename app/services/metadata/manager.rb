module Metadata
  class Manager
    def refresh_metadata!(objects)
      Array.wrap(objects).each { resolve_handler(it).refresh_metadata! }
    end

  private

    def resolve_handler(object)
      Metadata::Resolver.resolve_handler(object)
    end
  end
end
