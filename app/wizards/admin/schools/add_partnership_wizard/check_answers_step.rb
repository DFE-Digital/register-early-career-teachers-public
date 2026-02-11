module Admin
  module Schools
    module AddPartnershipWizard
      class CheckAnswersStep < Step
        def previous_step = :select_delivery_partner

        def save!
          SchoolPartnerships::Create.new(
            author: wizard.author,
            school: wizard.school,
            lead_provider_delivery_partnership: wizard.lead_provider_delivery_partnership
          ).create
        end
      end
    end
  end
end
