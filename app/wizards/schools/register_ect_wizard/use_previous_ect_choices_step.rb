module Schools
  module RegisterECTWizard
    class UsePreviousECTChoicesStep < Step
      attribute :use_previous_ect_choices, :boolean

      validates :use_previous_ect_choices,
                inclusion: {
                  in: [true, false],
                  message: "Select 'Yes' or 'No' to confirm whether to use the programme choices used by your school previously"
                },
                if: :reusable_available?

      def self.permitted_params = %i[use_previous_ect_choices]

      def allowed? = reusable_available?

      def next_step
        use_previous_ect_choices ? :check_answers : fallback_step
      end

      def previous_step = :working_pattern

      def fallback_step
        school.independent? ? :independent_school_appropriate_body : :state_school_appropriate_body
      end

      def reusable_partnership_preview
        return if reusable_partnership_id.blank?

        SchoolPartnership.find_by(id: reusable_partnership_id)
      end

      def reusable_available?
        return false if current_contract_period.blank?

        provider_led_reusable? || school_led_reusable?
      end

      def provider_led_reusable?
        school.provider_led_training_programme_chosen? &&
          school.last_chosen_lead_provider.present?
      end

      def school_led_reusable?
        school.school_led_training_programme_chosen? &&
          school.last_chosen_appropriate_body_id.present?
      end

      def reusable_partnership_id
        @reusable_partnership_id ||= find_reusable_partnership_id
      end

      def current_contract_period
        @current_contract_period ||= ContractPeriod.current
      end

    private

      def persist
        return false unless ect.update(use_previous_ect_choices:, **choices)

        store[:school_partnership_to_reuse_id] = nil

        apply_partnership_reuse! if use_previous_ect_choices

        true
      end

      def apply_partnership_reuse!
        return if reusable_partnership_id.blank?
        return if reusable_partnership_in_current_year?

        store[:school_partnership_to_reuse_id] = reusable_partnership_id
      end

      def reusable_partnership_in_current_year?
        SchoolPartnership
          .joins(lead_provider_delivery_partnership: :active_lead_provider)
          .where(id: reusable_partnership_id)
          .where(active_lead_providers: { contract_period_year: current_contract_period.year })
          .exists?
      end

      def choices
        use_previous_ect_choices ? school.last_programme_choices : {}
      end

      def find_reusable_partnership_id
        return if school.school_led_training_programme_chosen?

        SchoolPartnerships::FindReusablePartnership
          .new
          .call(
            school:,
            lead_provider: school.last_chosen_lead_provider,
            contract_period: current_contract_period
          )
          &.id
      end

      def provider_led_programme_chosen?
        school.provider_led_training_programme_chosen?
      end

      def last_chosen_lead_provider_present?
        school.last_chosen_lead_provider.present?
      end
    end
  end
end
