module API::FindDeclaration
  extend ActiveSupport::Concern

  def declaration
    @declaration ||= Declaration.find_by!(api_id: declaration_api_id)
  end
end
