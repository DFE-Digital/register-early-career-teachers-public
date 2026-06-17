module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriod
        class CurrentActivePeriod
          class UnsupportedTrainingPeriodError < StandardError; end
          class ScheduleNotFoundError < StandardError; end

          attr_reader :training_period, :contract_period, :school_partnership, :author

          def initialize(training_period:, contract_period:, school_partnership:, author:)
            @training_period = training_period
            @contract_period = contract_period
            @school_partnership = school_partnership
            @author = author
          end

          def change_contract_period!
            unless current_active_period?
              raise UnsupportedTrainingPeriodError,
                    "Contract period changes are only supported for the current active training period"
            end

            if equivalent_schedule.blank?
              raise ScheduleNotFoundError,
                    "No equivalent schedule found for #{training_period.schedule.identifier} in contract period #{contract_period.year}"
            end

            ActiveRecord::Base.transaction do
              track_payments_frozen_year!
              replacement_finished_on = training_period.finished_on
              finish_training_period!
              new_training_period = create_replacement_training_period!(finished_on: replacement_finished_on)
              record_contract_period_changed_event!
              new_training_period
            end
          end

        private

          def current_active_period?
            relationships.current_active_period == training_period && training_period.started_on < Time.zone.today
          end

          def relationships
            @relationships ||= ::TrainingPeriods::PeriodRelationships.new(training_period:)
          end

          def equivalent_schedule
            @equivalent_schedule ||= Schedule.find_by(
              identifier: training_period.schedule.identifier,
              contract_period_year: contract_period.year
            )
          end

          def finish_training_period!
            if training_period.for_ect?
              ::TrainingPeriods::Finish.ect_training(
                author:,
                training_period:,
                ect_at_school_period: training_period.at_school_period,
                finished_on: Date.yesterday
              ).finish!
            elsif training_period.for_mentor?
              ::TrainingPeriods::Finish.mentor_training(
                author:,
                training_period:,
                mentor_at_school_period: training_period.at_school_period,
                finished_on: Date.yesterday
              ).finish!
            else
              raise UnsupportedTrainingPeriodError, "Training period must be ECT or mentor"
            end
          end

          def create_replacement_training_period!(finished_on:)
            ::TrainingPeriods::Create.provider_led(
              period: training_period.at_school_period,
              started_on: Time.zone.today,
              finished_on:,
              school_partnership:,
              expression_of_interest: nil,
              schedule: equivalent_schedule,
              author:
            ).call
          end

          def record_contract_period_changed_event!
            ::Events::Record.record_teacher_contract_period_changed_event!(
              author:,
              original_training_period: training_period,
              teacher: training_period.teacher,
              from_contract_period: current_contract_period,
              to_contract_period: contract_period
            )
          end

          def current_contract_period
            @current_contract_period ||= training_period.contract_period
          end

          def track_payments_frozen_year!
            return if current_contract_period == contract_period

            if changing_from_payments_frozen_contract_period?
              set_payments_frozen_year(year: current_contract_period.year)
            elsif changing_to_payments_frozen_contract_period?
              set_payments_frozen_year(year: nil)
            end
          end

          def changing_from_payments_frozen_contract_period?
            current_contract_period.payments_frozen?
          end

          def changing_to_payments_frozen_contract_period?
            contract_period.payments_frozen?
          end

          def set_payments_frozen_year(year:)
            attribute = if training_period.for_ect?
                          :ect_payments_frozen_year
                        elsif training_period.for_mentor?
                          :mentor_payments_frozen_year
                        else
                          raise UnsupportedTrainingPeriodError, "Training period must be ECT or mentor"
                        end

            training_period.teacher.update!(attribute => year)
          end
        end
      end
    end
  end
end
