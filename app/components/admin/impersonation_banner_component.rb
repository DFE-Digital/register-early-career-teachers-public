module Admin
  class ImpersonationBannerComponent < ApplicationComponent
    attr_reader :user, :organisation

    def initialize(user:, organisation:)
      @user = user
      @organisation = organisation
    end

    def render?
      user.present? && organisation.present? &&
        (user.dfe_user_impersonating_school_user? ||
          user.dfe_user_impersonating_appropriate_body_user?)
    end
  end
end
