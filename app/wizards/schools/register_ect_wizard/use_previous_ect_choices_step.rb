module Schools
  module RegisterECTWizard
    class UsePreviousECTChoicesStep < Step
      attribute :use_previous_ect_choices, :boolean

      validates :use_previous_ect_choices,
                inclusion: {
                  in: [true, false],
                  message: "Select 'Yes' or 'No' to confirm whether to use the programme choices used by your school previously"
                }

      def self.permitted_params
        %i[use_previous_ect_choices]
      end

      def next_step
        return :check_answers if use_previous_ect_choices
        return :independent_school_appropriate_body if school.independent?

        :state_school_appropriate_body
      end

      def previous_step
        :working_pattern
      end

      def reusable_partnership_preview
        return nil unless preview_eligible?

        @reusable_partnership_preview ||= SchoolPartnerships::FindPreviousReusable.new.call(
          school:,
          last_lead_provider: school.last_chosen_lead_provider,
          current_contract_period: ect.contract_start_date
        )
      end

    private

      def persist
        return false unless ect.update(use_previous_ect_choices:, **choices)

        store.school_partnership_to_reuse_id =
          use_previous_ect_choices ? reusable_partnership_preview&.id : nil
        true
      end

      def preview_eligible?
        return false unless school.provider_led_training_programme_chosen?
        return false if school.last_chosen_lead_provider.blank?
        return false if current_year_partnership_exists?

        true
      end

      def current_year_partnership_exists?
        SchoolPartnerships::Search
          .new(school:, contract_period: ect.contract_start_date, lead_provider: school.last_chosen_lead_provider)
          .exists?
      end

      def choices
        use_previous_ect_choices ? school.last_programme_choices : {}
      end
    end
  end
end
