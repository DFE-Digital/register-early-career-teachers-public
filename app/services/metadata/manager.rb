module Metadata
  class Manager
    def create_metadata!(objects)
      Array.wrap(objects).each { resolve_handler(it).create_metadata!(it) }
    end

    def update_metadata!(objects)
      Array.wrap(objects).each { resolve_handler(it).update_metadata!(it) }
    end

  private

    def resolve_handler(object)
      Metadata::Resolver.resolve_handler(object)
    end
  end
end
