module API::Concerns::LeadProviderAuthorable
  extend ActiveSupport::Concern

  def author
    @author ||= Events::LeadProviderAPIAuthor.new(lead_provider:)
  end
end
