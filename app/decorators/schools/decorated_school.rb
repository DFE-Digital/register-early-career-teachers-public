module Schools
  class DecoratedSchool < SimpleDelegator
    def latest_registration_choices(contract_period: ContractPeriod.containing_date(Time.zone.today))
      @latest_registration_choices ||= Schools::LatestRegistrationChoices.new(school: self, contract_period:)
    end

    def has_partnership_with?(lead_provider:, contract_period:)
      SchoolPartnerships::Search.new(lead_provider:, contract_period:).exists?
    end

    def needs_lead_provider_confirmation_message?(ect:)
      return false unless provider_led_training_programme_chosen?

      lead_provider = latest_registration_choices&.lead_provider
      start_date = ect&.contract_start_date

      return false unless lead_provider
      return false unless start_date

      lacks_partnership_with?(lead_provider:, contract_period: start_date)
    end

    def lead_provider_name
      latest_registration_choices&.lead_provider&.name
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

    def lacks_partnership_with?(lead_provider:, contract_period:)
      !has_partnership_with?(lead_provider:, contract_period:)
    end
  end
end
