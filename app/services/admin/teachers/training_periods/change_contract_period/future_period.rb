module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriod
        class FuturePeriod
          class UnsupportedTrainingPeriodError < StandardError; end
          class ScheduleNotFoundError < StandardError; end
          class ActiveLeadProviderNotFoundError < StandardError; end

          attr_reader :training_period, :contract_period, :school_partnership, :author

          def initialize(training_period:, contract_period:, school_partnership:, author:)
            @training_period = training_period
            @contract_period = contract_period
            @school_partnership = school_partnership
            @author = author
          end

          def change_contract_period!
            unless future_period_changeable?
              raise UnsupportedTrainingPeriodError,
                    "Contract period changes are only supported for eligible future training periods"
            end

            if equivalent_schedule.blank?
              raise ScheduleNotFoundError,
                    "No equivalent schedule found for #{training_period.schedule.identifier} in contract period #{contract_period.year}"
            end

            if training_period.only_expression_of_interest? && equivalent_active_lead_provider.blank?
              raise ActiveLeadProviderNotFoundError,
                    "No active lead provider found for #{training_period.expression_of_interest_lead_provider.name} in contract period #{contract_period.year}"
            end

            ActiveRecord::Base.transaction do
              previous_contract_period = current_contract_period

              training_period.update!(training_period_attributes)

              record_contract_period_changed_event!(from_contract_period: previous_contract_period)
              training_period
            end
          end

        private

          def future_period_changeable?
            training_period.started_on > Time.zone.today &&
              Eligibility.new(training_period:).eligible?
          end

          def equivalent_schedule
            @equivalent_schedule ||= Schedule.find_by(
              identifier: training_period.schedule.identifier,
              contract_period_year: contract_period.year
            )
          end

          def training_period_attributes
            {
              school_partnership: replacement_school_partnership,
              schedule: equivalent_schedule,
              **expression_of_interest_attributes
            }
          end

          def replacement_school_partnership
            return if training_period.only_expression_of_interest?

            school_partnership
          end

          def expression_of_interest_attributes
            return {} unless training_period.only_expression_of_interest?

            { expression_of_interest: equivalent_active_lead_provider }
          end

          def equivalent_active_lead_provider
            return unless training_period.only_expression_of_interest?

            @equivalent_active_lead_provider ||= ActiveLeadProvider.find_by(
              lead_provider: training_period.expression_of_interest_lead_provider,
              contract_period:
            )
          end

          def current_contract_period
            @current_contract_period ||= training_period.contract_period || training_period.expression_of_interest_contract_period
          end

          def record_contract_period_changed_event!(from_contract_period:)
            ::Events::Record.record_teacher_contract_period_changed_event!(
              author:,
              original_training_period: training_period,
              new_training_period: training_period,
              teacher: training_period.teacher,
              from_contract_period:,
              to_contract_period: contract_period
            )
          end
        end
      end
    end
  end
end
