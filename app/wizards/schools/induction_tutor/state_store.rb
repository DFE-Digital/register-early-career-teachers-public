module Schools::InductionTutor
  class StateStore
    include DfE::Wizard::StateStore

    attr_reader :school

    def initialize(school:, **)
      super(**)
      @school = school
    end

    def details_confirmed? = read[:are_these_details_correct] == true

    def closest_contract_period
      @closest_contract_period ||= ContractPeriod.current_or_upcoming
    end
  end
end
