module Schools::InductionTutor
  class StateStore
    include DfE::Wizard::StateStore

    attr_reader :school

    def initialize(school:, **)
      super(**)
      @school = school
    end

    def prefill_from_school
      return if read[:induction_tutor_name].present? || read[:induction_tutor_email].present?

      write(
        induction_tutor_name: school.induction_tutor_name,
        induction_tutor_email: school.induction_tutor_email
      )
    end

    def details_confirmed? = read[:are_these_details_correct] == true

    def closest_contract_period
      @closest_contract_period ||= ContractPeriod.current_or_upcoming
    end
  end
end
