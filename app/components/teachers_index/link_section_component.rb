module TeachersIndex
  class LinkSectionComponent < ViewComponent::Base
    include GovukLinkHelper
    include Rails.application.routes.url_helpers

    def initialize(bulk_upload_enabled:)
      @bulk_upload_enabled = bulk_upload_enabled
    end

  private

    attr_reader :bulk_upload_enabled

    def bulk_upload_enabled?
      bulk_upload_enabled
    end
  end
end
