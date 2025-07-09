module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true
      validate :start_date_not_before_previous_school

      def self.permitted_params
        %i[start_date]
      end

      def next_step
        return :working_pattern if past_start_date? || start_date_contract_period&.enabled?

        :cannot_register_ect_yet
      end

      def previous_step
        :email_address
      end

    private

      def start_date_not_before_previous_school
        return if start_date.blank? || errors[:start_date].any?

        previous_period = ect.previous_ect_at_school_period
        return if previous_period.blank? || previous_period.started_on.blank?

        if start_date_as_date < previous_period.started_on
          errors.add(
            :start_date,
            "This ECT was previously registered at #{previous_period.school&.name} (#{previous_period.started_on.to_formatted_s(:govuk)}). Enter a later date."
          )
        end
      end

      def persist
        ect.update!(start_date: start_date_formatted)
      end

      def pre_populate_attributes
        self.start_date = Schools::Validation::ECTStartDate.new(date_as_hash: ect.start_date).date_as_hash unless start_date
      end

      def start_date_formatted
        @start_date_formatted ||= start_date_obj.formatted_date
      end

      def start_date_as_date
        @start_date_as_date ||= start_date_obj.value_as_date
      end

      def past_start_date?
        start_date_as_date < Date.current
      end

      def start_date_contract_period
        @start_date_contract_period ||= ContractPeriod.ongoing_on(start_date_as_date).first
      end

      def start_date_obj
        @start_date_obj ||= Schools::Validation::ECTStartDate.new(date_as_hash: start_date)
      end
    end
  end
end
