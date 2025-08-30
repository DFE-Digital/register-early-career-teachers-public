module Queries
  module AssociationPreloadable
    extend ActiveSupport::Concern

  protected

    # Hook for subclasses to preload/include associations.
    def preload_associations(result) = result
  end
end
