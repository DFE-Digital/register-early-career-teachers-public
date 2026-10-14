module Schools::AssignExistingMentorWizard
  class StateStore
    include DfE::Wizard::StateStore

    REPOSITORY_KEY = "assign_existing_mentor_wizard"

    def started? = ect_id.present? && mentor_period_id.present?

    def ect_id = read[:ect_id]
    def mentor_period_id = read[:mentor_period_id]

    def ect_at_school_period
      @ect_at_school_period ||= ECTAtSchoolPeriod.find(ect_id)
    end

    def mentor_at_school_period
      @mentor_at_school_period ||= MentorAtSchoolPeriod.find(mentor_period_id)
    end

    def ect_teacher_full_name = ::Teachers::Name.new(ect_at_school_period.teacher).full_name
    def mentor_teacher_full_name = ::Teachers::Name.new(mentor_at_school_period.teacher).full_name

    def ect_lead_provider
      @ect_lead_provider ||= ect_current_training.lead_provider_via_school_partnership_or_eoi
    end

    def ect_lead_provider_available? = ect_current_training.lead_provider_available_for_training?

    def lead_providers_within_contract_period
      contract_period = ContractPeriod.current
      return [] unless contract_period

      LeadProviders::Active.in_contract_period(contract_period).select(:id, :name)
    end

  private

    def ect_current_training
      @ect_current_training ||= ECTAtSchoolPeriods::CurrentTraining.new(ect_at_school_period)
    end
  end
end
