module API::Concerns::DeclarationValidatable
  extend ActiveSupport::Concern

  included do
    include API::Concerns::LeadProviderValidatable

    attribute :declaration_api_id
  end

private

  def declaration
    @declaration ||= Declaration.find_by!(api_id: declaration_api_id)
  end
end
