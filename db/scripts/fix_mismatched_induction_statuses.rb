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
  SELECT t.id
  FROM teachers t
  INNER JOIN latest_induction_periods lip ON t.id = lip.teacher_id
  WHERE lip.outcome IN ('pass', 'fail')
  AND t.trs_induction_status = 'InProgress'
SQL

mismatched_teacher_ids = ActiveRecord::Base.connection.execute(sql).map { |r| r["id"] }
mismatched_teachers = Teacher.where(id: mismatched_teacher_ids)

Rails.logger.debug "Found #{mismatched_teachers.count} teachers with mismatched statuses"

mismatched_teachers.each do |teacher|
  trn = teacher.trn
  Rails.logger.debug "[TRN: #{trn}] Processing teacher..."

  # Sync with TRS
  Rails.logger.debug "[TRN: #{trn}] Syncing with TRS..."
  begin
    Teachers::RefreshTRSAttributes.new(teacher).refresh!
  rescue TRS::Errors::TeacherNotFound
    Rails.logger.debug "[TRN: #{trn}] Teacher not found in TRS, skipping..."
    next
  end

  # Check if TRS status now matches outcome
  teacher.reload
  latest_period = teacher.induction_periods.order(started_on: :desc).first

  expected_status = case latest_period.outcome
                    when 'pass' then 'Passed'
                    when 'fail' then 'Failed'
                    end

  if teacher.trs_induction_status == expected_status
    Rails.logger.debug "[TRN: #{trn}] Status now matches outcome, skipping..."
    next
  end

  # If still mismatched, send update to TRS
  Rails.logger.debug "[TRN: #{trn}] Status still mismatched:"
  Rails.logger.debug "[TRN: #{trn}]   - Our status: #{teacher.trs_induction_status}"
  Rails.logger.debug "[TRN: #{trn}]   - Expected status: #{expected_status}"
  Rails.logger.debug "[TRN: #{trn}]   - Induction outcome: #{latest_period.outcome}"
  Rails.logger.debug "[TRN: #{trn}] Sending update to TRS..."

  begin
    if latest_period.outcome == 'pass'
      TRS::APIClient.new.pass_induction!(
        trn:,
        start_date: latest_period.started_on,
        completed_date: latest_period.finished_on
      )
    elsif latest_period.outcome == 'fail'
      TRS::APIClient.new.fail_induction!(
        trn:,
        start_date: latest_period.started_on,
        completed_date: latest_period.finished_on
      )
    end
    Rails.logger.debug "[TRN: #{trn}] Successfully updated TRS"
  rescue StandardError => e
    Rails.logger.debug "[TRN: #{trn}] Error updating TRS: #{e.message}"
  end

  # Small delay to avoid rate limiting
  sleep(1)
end

Rails.logger.debug "Script completed"
