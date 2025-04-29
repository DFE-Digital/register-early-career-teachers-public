#!/usr/bin/env ruby
# frozen_string_literal: true

# This script finds teachers whose latest induction period has a pass/fail outcome
# but their TRS status is still 'InProgress'. It then:
# 1. Syncs with TRS to get latest status
# 2. If still mismatched, sends the appropriate update to TRS

require 'trs/api_client'

# First get all teachers with mismatched statuses
sql = <<-SQL
  WITH latest_induction_period_start AS (
    SELECT teacher_id, MAX(started_on) as latest_started_on
    FROM induction_periods
    GROUP BY teacher_id
  ),
  latest_induction_periods AS (
    SELECT ip.*
    FROM induction_periods ip
    INNER JOIN latest_induction_period_start lips
      ON lips.teacher_id = ip.teacher_id
      AND lips.latest_started_on = ip.started_on
  )
  SELECT
    t.id as teacher_id,
    t.trn,
    lip.outcome,
    t.trs_induction_status
  FROM teachers t
  INNER JOIN latest_induction_periods lip ON t.id = lip.teacher_id
  WHERE lip.outcome IN ('pass', 'fail')
  AND t.trs_induction_status = 'InProgress'
SQL

mismatched_teachers = Teacher.find_by_sql(sql)

Rails.logger.debug "Found #{mismatched_teachers.count} teachers with mismatched statuses"

mismatched_teachers.each do |teacher_data|
  teacher = Teacher.find(teacher_data.teacher_id)

  Rails.logger.debug "Processing teacher #{teacher.trn}..."

  # Sync with TRS
  Rails.logger.debug "  Syncing with TRS..."
  Teachers::RefreshTRSAttributes.new(teacher).refresh!

  # Check if TRS status now matches outcome
  teacher.reload
  if teacher.trs_induction_status == teacher_data.outcome.capitalize
    Rails.logger.debug "  Status now matches outcome, skipping..."
    next
  end

  # If still mismatched, send update to TRS
  Rails.logger.debug "  Status still mismatched, sending update to TRS..."
  begin
    if teacher_data.outcome == 'pass'
      TRS::APIClient.new.pass_induction!(
        trn: teacher.trn,
        start_date: teacher.induction_periods.last.started_on,
        completed_date: teacher.induction_periods.last.finished_on
      )
    elsif teacher_data.outcome == 'fail'
      TRS::APIClient.new.fail_induction!(
        trn: teacher.trn,
        start_date: teacher.induction_periods.last.started_on,
        completed_date: teacher.induction_periods.last.finished_on
      )
    end
    Rails.logger.debug "  Successfully updated TRS"
  rescue StandardError => e
    Rails.logger.debug "  Error updating TRS: #{e.message}"
  end

  # Small delay to avoid rate limiting
  sleep(1)
end

Rails.logger.debug "Script completed"
