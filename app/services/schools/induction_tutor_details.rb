module Schools
  class InductionTutorDetails
    include Rails.application.routes.url_helpers
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def update_required?
      return unless Rails.configuration.prompt_for_school_induction_tutor_details
      return unless user&.school_user?
      return if user.dfe_user_impersonating_school_user?
      return if user.has_multiple_roles?
      return unless school

      last_updated_year.blank? || last_updated_year < current_contract_year
    end

    # TODO: A subsequent PR will check whether the induction tutor details are present
    # If they are not we'll probably redirect to a different wizard
    def wizard_path
      schools_confirm_existing_induction_tutor_wizard_edit_path
    end

  private

    def current_contract_year
      ContractPeriod.containing_date(Time.zone.today).year
    end

    def school
      @school ||= @user&.school
    end

    def last_updated_year
      @user.school.induction_tutor_last_nominated_in_year&.year
    end
  end
end
