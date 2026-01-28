module Admin
  module Schools
    module AddPartnershipWizard
      class CheckAnswersStep < Step
        validate :partnership_unique

        def previous_step = :select_delivery_partner

        def save!
          return false unless valid?

          # rubocop:disable Rails/SaveBang
          SchoolPartnerships::Create.new(
            author: wizard.author,
            school: wizard.school,
            lead_provider_delivery_partnership: wizard.lead_provider_delivery_partnership
          ).create
          # rubocop:enable Rails/SaveBang

          wizard.store.reset
        end

      private

        def partnership_unique
          return if wizard.lead_provider_delivery_partnership.blank?

          return unless SchoolPartnership.exists?(
            school: wizard.school,
            lead_provider_delivery_partnership: wizard.lead_provider_delivery_partnership
          )

          errors.add(:base, "Partnership already exists for this school")
        end
      end
    end
  end
end
