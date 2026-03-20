module ContractPeriods
  class Historic
    CLOSED_CONTRACT_YEARS = [2021, 2022].freeze
    REPLACEMENT_CONTRACT_YEAR = 2024

    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end

    def self.ect_training_started_in_closed_contract_period?(teacher:)
      new(teacher:).training_started_in_closed_contract_period?
    end

    def training_started_in_closed_contract_period?
      return false if teacher.blank?
      return false unless teacher.ect_at_school_periods.exists?

      training_periods_in_closed_contracts.exists?
    end

    def self.closed_contract_periods
      @closed_contract_periods ||= ContractPeriod.where(year: CLOSED_CONTRACT_YEARS).to_a
    end

    def self.replacement_contract_period
      @replacement_contract_period ||= ContractPeriod.find_by!(year: REPLACEMENT_CONTRACT_YEAR)
    end

  private

    def training_periods_in_closed_contracts
      teacher
        .ect_training_periods
        .joins(:contract_period)
        .where(contract_periods: { year: CLOSED_CONTRACT_YEARS })
    end
  end
end
