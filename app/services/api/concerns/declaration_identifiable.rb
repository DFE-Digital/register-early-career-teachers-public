module API::Concerns::DeclarationIdentifiable
  extend ActiveSupport::Concern

  included do
    attribute :declaration_api_id
  end

private

  def declaration
    @declaration ||= Declaration.find_by!(api_id: declaration_api_id)
  end
end
