module API::V3::SchoolPartnerships
  class Create < ::API::SchoolPartnerships::BaseCreate
    validate :contract_period_started

  private

    def contract_period_started
      return if errors[:contract_period_year].any?

      errors.add(:contract_period_year, "You cannot create a partnership for a future contract period.") unless contract_period&.started_on_or_before_today?
    end
  end
end
