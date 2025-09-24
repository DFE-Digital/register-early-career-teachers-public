def describe_teacher(teacher)
  teacher_name = "#{teacher.trs_first_name} #{teacher.trs_last_name}"

  ero_status = if teacher.mentor_became_ineligible_for_funding_reason == 'completed_during_early_roll_out'
                 Colourize.text('yes', :green)
               else
                 Colourize.text('no', :red)
               end

  payments_frozen =
    if teacher.ect_payments_frozen_year.present? && teacher.mentor_payments_frozen_year.present?
      Colourize.text('ECT/mentor', :green)
    elsif teacher.ect_payments_frozen_year.present?
      Colourize.text('ECT', :green)
    elsif teacher.mentor_payments_frozen_year.present?
      Colourize.text('mentor', :green)
    else
      Colourize.text('no', :red)
    end

  id_changes = if teacher.teacher_id_changes.present?
                 Colourize.text('yes', :green)
               else
                 Colourize.text('no', :red)
               end

  uplift =
    if teacher.ect_pupil_premium_uplift || teacher.ect_sparsity_uplift
      Colourize.text('yes', :green)
    else
      Colourize.text('no', :red)
    end

  print_seed_info("#{teacher_name} (early roll out mentor: #{ero_status}, payments frozen: #{payments_frozen}, id changes: #{id_changes}, uplift: #{uplift})", indent: 2)
end

early_roll_out_mentor_attrs = {
  mentor_became_ineligible_for_funding_reason: 'completed_during_early_roll_out',
  mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19)
}

uplift_attrs = {
  ect_sparsity_uplift: true,
  ect_pupil_premium_uplift: true,
}

teachers = [
  { trs_first_name: 'Emma', trs_last_name: 'Thompson', trn: '1023456', trs_induction_status: 'InProgress', **uplift_attrs },
  { trs_first_name: 'Kate', trs_last_name: 'Winslet', trn: '1023457', trs_induction_status: 'Passed', **uplift_attrs },
  { trs_first_name: 'Alan', trs_last_name: 'Rickman', trn: '2084589', trs_induction_status: 'RequiredToComplete' },
  { trs_first_name: 'Hugh', trs_last_name: 'Grant', trn: '3657894', trs_induction_status: 'Failed' },
  { trs_first_name: 'Colin', trs_last_name: 'Firth', trn: '1237894', trs_induction_status: 'Exempt' },
  { trs_first_name: 'Harriet', trs_last_name: 'Walter', trn: '2017654', trs_induction_status: 'InProgress', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Hugh', trs_last_name: 'Laurie', trn: '4786654', trs_induction_status: 'Passed', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Stephen', trs_last_name: 'Fry', trn: '4786655', trs_induction_status: 'RequiredToComplete' },
  { trs_first_name: 'André', trs_last_name: 'Roussimoff', trn: '8886654', trs_induction_status: 'FailedInWales' },
  { trs_first_name: 'Imogen', trs_last_name: 'Stubbs', trn: '6352869', trs_induction_status: 'InProgress', ect_payments_frozen_year: 2021 },
  { trs_first_name: 'Gemma', trs_last_name: 'Jones', trn: '9578426', trs_induction_status: 'InProgress' },
  { trs_first_name: 'Anthony', trs_last_name: 'Hopkins', trn: '6228282', trs_induction_status: 'Exempt', mentor_payments_frozen_year: 2021 },
  { trs_first_name: 'John', trs_last_name: 'Withers', corrected_name: 'Old Man Withers', trn: '8590123', trs_induction_status: 'Failed' },
  { trs_first_name: 'Helen', trs_last_name: 'Mirren', corrected_name: 'Dame Helen Mirren', trn: '0000007', trs_induction_status: 'Passed' },
  { trs_first_name: 'Dominic', trs_last_name: 'West', trn: '9292929', trs_induction_status: 'InProgress' },
  { trs_first_name: 'Peter', trs_last_name: 'Davison', trn: '0011223', trs_induction_status: 'RequiredToComplete', ect_payments_frozen_year: 2022, mentor_payments_frozen_year: 2022 },
  { trs_first_name: 'Robson', trs_last_name: 'Scottie', trn: '3002582', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Muhammed', trs_last_name: 'Ali', trn: '3002580', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Roy', trs_last_name: 'Dotrice', trn: '7000007', **early_roll_out_mentor_attrs },
  { trs_first_name: 'Ichigo', trs_last_name: 'Kurosaki', trn: '7777654', trs_induction_status: 'InProgress' }
]

teachers.each do |attrs|
  FactoryBot.create(:teacher, attrs).tap do |teacher|
    FactoryBot.create(:teacher_id_change, teacher:) if Faker::Boolean.boolean(true_ratio: 0.2)

    describe_teacher(teacher)
  end
end
