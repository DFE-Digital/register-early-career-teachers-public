# These records are now invalid since changing the inclusivity of
# training period ranges
#
# Here, the query joins training periods to themselves using the teacher_id
# and gets earlier/later pairs by joining one record's started_on to the other
# record's finished_on
#
# Note, we're adding the 'type' field so we don't join ECT training periods to
# mentor training periods
#
# For each one of the results we want to push the finshed_on date one day earlier

query = <<~SQL
  with
    ect_data as (
      select easp.teacher_id, 'ect' as type, tp.id, tp.started_on, tp.finished_on
      from training_periods tp
      inner join ect_at_school_periods easp on tp.ect_at_school_period_id = easp.id
    ),
    mentor_data as (
      select masp.teacher_id, 'mentor' as type, tp.id, tp.started_on, tp.finished_on
      from training_periods tp
      inner join mentor_at_school_periods masp on tp.ect_at_school_period_id = masp.id
    ),
    all_data as (
      select * from ect_data
      union
      select * from mentor_data
    )
  select earlier.id
  from all_data earlier
  inner join all_data later
    on earlier.teacher_id = later.teacher_id
    and earlier.finished_on = later.started_on
    and earlier.type = later.type
SQL

result = ActiveRecord::Base.connection.execute(query)
training_periods_to_adjust = result.field_values("id")

TrainingPeriod.transaction do
  TrainingPeriod.where(id: training_periods_to_adjust).find_each do |training_period|
    training_period.update!(finished_on: training_period.finished_on.prev_day)
  end
end
