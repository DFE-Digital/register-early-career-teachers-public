module API::Concerns::ModelBehaviour
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end
