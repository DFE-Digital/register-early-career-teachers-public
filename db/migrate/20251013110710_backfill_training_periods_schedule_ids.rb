class BackfillTrainingPeriodsScheduleIds < ActiveRecord::Migration[8.0]
  def up
    TrainingPeriod.find_each do |training_period|
      contract_period = training_period.contract_period || training_period.expression_of_interest_contract_period

      default_schedule = Schedule.find_by(contract_period:, identifier: "ecf-standard-september")

      if default_schedule
        training_period.update!(schedule_id: default_schedule.id)
      else
        raise "No default schedule found for contract period id #{contract_period.id}"
      end
    end
  end

  def down
    TrainingPeriod.update_all(schedule_id: nil)
  end
end
