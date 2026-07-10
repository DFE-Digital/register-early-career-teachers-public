module API::V4::SchoolPartnerships
  class Create < ::API::SchoolPartnerships::Create
    validate :school_is_eligible

    private

    def school_is_eligible
      return if errors[:school_api_id].any?

      errors.add(:school_api_id, "The school you have entered is currently ineligible for DfE funding. Contact the school for more information.") unless school&.eligible?
    end
  end
end
