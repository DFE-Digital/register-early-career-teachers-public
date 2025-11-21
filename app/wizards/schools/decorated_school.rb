module Schools
  class DecoratedSchool < SimpleDelegator
    def latest_registration_choices(contract_period: ContractPeriod.containing_date(Time.zone.today))
      @latest_registration_choices ||= Schools::LatestRegistrationChoices.new(school: self, contract_period:)
    end

    def has_partnership_with?(lead_provider:, contract_period:)
      SchoolPartnerships::Search.new(lead_provider:, contract_period:).exists?
    end

    def show_previous_programme_choices_row?(wizard)
      last_programme_choices? &&
        reuse_previous_choices_step_allowed?(wizard) &&
        wizard.ect.use_previous_ect_choices
    end

  private

    def reuse_previous_choices_step_allowed?(wizard)
      Schools::RegisterECTWizard::UsePreviousECTChoicesStep
        .new(wizard:)
        .allowed?
    end
  end
end
