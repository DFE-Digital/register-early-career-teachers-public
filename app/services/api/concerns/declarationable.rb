module API::Concerns::Declarationable
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declaration_api_id

  end

private

  def declaration
    @declaration ||= Declaration.find_by!(api_id: declaration_api_id)
  end
end
