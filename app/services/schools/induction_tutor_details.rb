module Schools
  class InductionTutorDetails
    include Rails.application.routes.url_helpers
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def update_required?
      return unless Rails.configuration.enable_induction_tutor_prompt
      return unless user&.school_user?
      return if user.dfe_user_impersonating_school_user?
      return unless school

      last_updated_year.blank? || last_updated_year < ContractPeriod.current.year
    end

    def wizard_path
      if school.induction_tutor_email.present?
        schools_induction_tutor_confirm_existing_induction_tutor_wizard_edit_path
      else
        schools_induction_tutor_new_induction_tutor_wizard_edit_path
      end
    end

  private

    def school
      @school ||= @user&.school
    end

    def last_updated_year
      school.induction_tutor_last_nominated_in&.year
    end
  end
end
