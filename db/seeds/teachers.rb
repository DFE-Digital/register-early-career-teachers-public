def describe_teacher(teacher)
  teacher_name = "#{teacher.trs_first_name} #{teacher.trs_last_name}"

  ero_status = if teacher.mentor_became_ineligible_for_funding_reason == 'completed_during_early_roll_out'
                 Colourize.text('yes', :green)
               else
                 Colourize.text('no', :red)
               end

  print_seed_info("#{teacher_name} (early roll out mentor: #{ero_status})", indent: 2)
end

early_roll_out_mentor_attrs = {
  mentor_became_ineligible_for_funding_reason: 'completed_during_early_roll_out',
  mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19)
}

teachers = [
  { trs_first_name: 'Emma', trs_last_name: 'Thompson', trn: '1023456', trs_induction_status: 'InProgress' },
  { trs_first_name: 'Kate', trs_last_name: 'Winslet', trn: '1023457', trs_induction_status: 'Passed' },
  { trs_first_name: 'Alan', trs_last_name: 'Rickman', trn: '2084589', trs_induction_status: 'RequiredToComplete' },
  { trs_first_name: 'Hugh', trs_last_name: 'Grant', trn: '3657894', trs_induction_status: 'Failed' },
  { trs_first_name: 'Colin', trs_last_name: 'Firth', trn: '1237894', trs_induction_status: 'Exempt' },
  { trs_first_name: 'Harriet', trs_last_name: 'Walter', trn: '2017654', trs_induction_status: 'InProgress', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Hugh', trs_last_name: 'Laurie', trn: '4786654', trs_induction_status: 'Passed', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Stephen', trs_last_name: 'Fry', trn: '4786655', trs_induction_status: 'RequiredToComplete' },
  { trs_first_name: 'André', trs_last_name: 'Roussimoff', trn: '8886654', trs_induction_status: 'FailedInWales' },
  { trs_first_name: 'Imogen', trs_last_name: 'Stubbs', trn: '6352869', trs_induction_status: 'InProgress' },
  { trs_first_name: 'Gemma', trs_last_name: 'Jones', trn: '9578426', trs_induction_status: 'InProgress' },
  { trs_first_name: 'Anthony', trs_last_name: 'Hopkins', trn: '6228282', trs_induction_status: 'Exempt' },
  { trs_first_name: 'John', trs_last_name: 'Withers', corrected_name: 'Old Man Withers', trn: '8590123', trs_induction_status: 'Failed' },
  { trs_first_name: 'Helen', trs_last_name: 'Mirren', corrected_name: 'Dame Helen Mirren', trn: '0000007', trs_induction_status: 'Passed' },
  { trs_first_name: 'Robson', trs_last_name: 'Scottie', trn: '3002582', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Muhammed', trs_last_name: 'Ali', trn: '3002580', **early_roll_out_mentor_attrs }
]

teachers.each do |attrs|
  Teacher.create!(attrs).tap { |teacher| describe_teacher(teacher) }
end

# Find the Golden Leaf Teaching School Hub
golden_leaf_teaching_school_hub = AppropriateBody.find_by!(name: 'Golden Leaf Teaching School Hub')

# Create teachers with open inductions (100)
open_induction_statuses = %w[InProgress RequiredToComplete]
100.times do |i|
  trn = sprintf("%07d", 1_000_000 + i)
  teacher = Teacher.find_or_create_by!(trn:) do |t|
    t.trs_first_name = "Teacher#{i + 1}"
    t.trs_last_name = "Open#{i + 1}"
    t.trs_induction_status = open_induction_statuses.sample
  end

  # Create open induction period
  next if teacher.induction_periods.exists?

  InductionPeriod.create!(
    teacher:,
    appropriate_body: golden_leaf_teaching_school_hub,
    started_on: rand(12.months.ago..1.month.ago),
    finished_on: nil,
    induction_programme: 'fip'
  )
end

# Create teachers with closed inductions (100)
closed_induction_statuses = %w[Passed Failed FailedInWales Exempt]
100.times do |i|
  trn = sprintf("%07d", 2_000_000 + i)
  teacher = Teacher.find_or_create_by!(trn:) do |t|
    t.trs_first_name = "Teacher#{i + 1}"
    t.trs_last_name = "Closed#{i + 1}"
    t.trs_induction_status = closed_induction_statuses.sample
  end

  # Create closed induction period
  next if teacher.induction_periods.exists?

  start_date = rand(3.years.ago..2.years.ago)
  end_date = start_date + rand(6.months..12.months)

  # Set outcome based on TRS status - pass for Passed/Exempt, fail for Failed/FailedInWales
  outcome = if %w[Passed Exempt].include?(teacher.trs_induction_status)
              'pass'
            else
              'fail'
            end

  InductionPeriod.create!(
    teacher:,
    appropriate_body: golden_leaf_teaching_school_hub,
    started_on: start_date,
    finished_on: end_date,
    induction_programme: 'fip',
    number_of_terms: 3,
    outcome:
  )
end

Rails.logger.info "✅ Created #{teachers.length + 200} teachers:"
Rails.logger.info "   - #{teachers.length} specific named teachers"
Rails.logger.info "   - 100 with open induction statuses (InProgress/RequiredToComplete)"
Rails.logger.info "   - 100 with closed induction statuses (Passed/Failed/FailedInWales/Exempt)"
Rails.logger.info "   - 200 additional teachers associated with Golden Leaf Teaching School Hub"
