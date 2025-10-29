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
        SchoolPartnership.find_by(id: reusable_partnership_id)
      end

      def reusable_available?
        provider_led_programme_chosen? &&
          last_chosen_lead_provider_present? &&
          current_contract_year.present? &&
          reusable_partnership_id.present?
      end

      def reusable_partnership_id
        @reusable_partnership_id ||= find_previous_year_reusable_id
      end

      def current_contract_year
        @current_contract_year ||= ect.normalized_start_date&.year
      end

    private

      def persist
        return false unless ect.update(use_previous_ect_choices:, **choices)

        store[:school_partnership_to_reuse_id] =
          (reusable_available? && use_previous_ect_choices) ? reusable_partnership_id : nil

        true
      end

      def choices
        use_previous_ect_choices ? school.last_programme_choices : {}
      end

      def find_previous_year_reusable_id
        SchoolPartnerships::FindPreviousReusable
          .new
          .call(
            school:,
            last_lead_provider: school.last_chosen_lead_provider,
            current_contract_period: current_contract_year
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
