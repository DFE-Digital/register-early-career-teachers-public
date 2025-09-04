module Admin
  class ImpersonationBannerComponent < ViewComponent::Base
    attr_reader :user, :school

    def initialize(user:, school:)
      @user = user
      @school = school
    end

    def render?
      user.present? && school.present? && user.dfe_user_impersonating_school_user?
    end
  end
end
