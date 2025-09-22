module Schools
  class DecoratedSchool < SimpleDelegator
    def latest_registration_choices(contract_period: ContractPeriod.containing_date(Time.zone.today))
      @latest_registration_choices ||= Schools::LatestRegistrationChoices.new(school: self, contract_period:)
    end

    def has_partnership_with?(lead_provider:, contract_period:)
      SchoolPartnerships::Search.new(lead_provider:, contract_period:).exists?
    end
  end
end
