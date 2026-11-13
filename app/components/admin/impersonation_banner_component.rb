module Admin
  class ImpersonationBannerComponent < ApplicationComponent
    attr_reader :user, :organisation

    def initialize(user:)
      @user = user
      @organisation = if @user&.dfe_user_impersonating_school_user?
                        @user.school
                      elsif @user&.dfe_user_impersonating_appropriate_body_user?
                        @user.appropriate_body_period
                      end
    end

    def render?
      user.present? && organisation.present? && user.impersonating?
    end
  end
end
