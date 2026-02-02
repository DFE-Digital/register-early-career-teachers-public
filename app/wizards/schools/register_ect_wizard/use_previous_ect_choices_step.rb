module Schools
  module RegisterECTWizard
    class UsePreviousECTChoicesStep < Step
      attribute :use_previous_ect_choices, :boolean

      validates :use_previous_ect_choices,
                inclusion: {
                  in: [true, false],
                  message: "Select 'Yes' or 'No' to confirm whether to use the programme choices used by your school previously"
                },
                if: :allowed?

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
        provider_led_reusable? || school_led_reusable?
      end

      def provider_led_reusable?
        return false unless school.provider_led_training_programme_chosen?
        return false if school.last_chosen_lead_provider.blank?

        reusable_partnership_id.present? || reusable_expression_of_interest?
      end

      def school_led_reusable?
        school.school_led_training_programme_chosen? &&
          school.last_chosen_appropriate_body_id.present?
      end

      def reusable_partnership_id
        @reusable_partnership_id ||= find_reusable_partnership_id
      end

      def registration_contract_period
        start_date = ect.normalized_start_date
        return unless start_date

        ContractPeriod.for_registration_start_date(start_date)
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
        return if reusable_partnership_in_registration_year?

        store[:school_partnership_to_reuse_id] = reusable_partnership_id
      end

      def find_reusable_partnership_id
        return if school.school_led_training_programme_chosen?
        return if school.last_chosen_lead_provider.blank?

        contract_period = registration_contract_period
        return unless contract_period

        SchoolPartnerships::FindReusablePartnership
          .new(
            school:,
            lead_provider: school.last_chosen_lead_provider,
            contract_period:
          )
          .call
          &.id
      end

      def choices
        use_previous_ect_choices ? school.last_programme_choices : {}
      end

      def reusable_expression_of_interest?
        contract_period = registration_contract_period
        return false unless contract_period

        training_period =
          most_recent_provider_led_expression_of_interest_training_period_up_to(contract_period)
        return false unless training_period

        active_lead_provider =
          ActiveLeadProvider.find_by(id: training_period.expression_of_interest_id)
        return false unless active_lead_provider

        ActiveLeadProvider.exists?(
          contract_period_year: contract_period.year,
          lead_provider_id: active_lead_provider.lead_provider_id
        )
      end

      def reusable_partnership_in_registration_year?
        contract_period = registration_contract_period
        return false unless reusable_partnership_id && contract_period

        SchoolPartnership
          .joins(lead_provider_delivery_partnership: :active_lead_provider)
          .where(id: reusable_partnership_id)
          .where(active_lead_providers: { contract_period_year: contract_period.year })
          .exists?
      end

      def most_recent_provider_led_expression_of_interest_training_period_up_to(contract_period)
        return unless contract_period

        TrainingPeriod
          .at_school(school)
          .where(training_programme: "provider_led")
          .where.not(expression_of_interest_id: nil)
          .where("training_periods.started_on <= ?", contract_period.finished_on)
          .order(started_on: :desc, id: :desc)
          .first
      end
    end
  end
end
