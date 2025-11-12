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

# NB: seeded teachers MUST NOT use TRNs found in TRS otherwise data refreshes alter status indicators and names
teachers = [
  { trn: '0000001', trs_first_name: 'Stephen', trs_last_name: 'Griddle', trs_induction_status: 'InProgress' },
  { trn: '0000002', trs_first_name: 'Dominic', trs_last_name: 'East', trs_induction_status: 'InProgress' },
  { trn: '0000003', trs_first_name: 'Hugh', trs_last_name: 'Stipend',  trs_induction_status: 'Failed' },
  { trn: '0000004', trs_first_name: 'Emma', trs_last_name: 'Thompson', trs_induction_status: 'InProgress', **uplift_attrs },
  { trn: '0000005', trs_first_name: 'Kate', trs_last_name: 'Winslet',  trs_induction_status: 'Passed', **uplift_attrs },
  { trn: '0000006', trs_first_name: 'Alan', trs_last_name: 'Rickman',  trs_induction_status: 'RequiredToComplete' },
  { trn: '0000007', trs_first_name: 'Colin', trs_last_name: 'Firth',  trs_induction_status: 'Exempt' },
  { trn: '0000008', trs_first_name: 'Robert', trs_last_name: 'Webb',  **early_roll_out_mentor_attrs },
  { trn: '0000009', trs_first_name: 'David', trs_last_name: 'Mitchell', **early_roll_out_mentor_attrs },
  { trn: '0000010', trs_first_name: 'Harriet', trs_last_name: 'Walter', trs_induction_status: 'InProgress', **early_roll_out_mentor_attrs },
  { trn: '0000011', trs_first_name: 'Hugh', trs_last_name: 'Laurie', trs_induction_status: 'Passed', **early_roll_out_mentor_attrs },
  { trn: '0000013', trs_first_name: 'Stephen', trs_last_name: 'Fry', trs_induction_status: 'RequiredToComplete', id_changed_from_trn: '0000001', traits: %i[with_teacher_id_change] },
  { trn: '0000014', trs_first_name: 'Dominic', trs_last_name: 'West', trs_induction_status: 'InProgress', id_changed_from_trn: '0000002', traits: %i[with_teacher_id_change] },
  { trn: '0000012', trs_first_name: 'Hugh', trs_last_name: 'Grant', trs_induction_status: 'Failed', id_changed_from_trn: '0000003', traits: %i[with_teacher_id_change] },
  { trn: '0000015', trs_first_name: 'André', trs_last_name: 'Roussimoff', trs_induction_status: 'FailedInWales' },
  { trn: '0000016', trs_first_name: 'Imogen', trs_last_name: 'Stubbs', trs_induction_status: 'InProgress', ect_payments_frozen_year: 2021 },
  { trn: '0000017', trs_first_name: 'Gemma', trs_last_name: 'Jones', trs_induction_status: 'InProgress' },
  { trn: '0000018', trs_first_name: 'Anthony', trs_last_name: 'Hopkins', trs_induction_status: 'Exempt', mentor_payments_frozen_year: 2021 },
  { trn: '0000019', trs_first_name: 'John', trs_last_name: 'Withers', corrected_name: 'Old Man Withers', trs_induction_status: 'Failed' },
  { trn: '0000020', trs_first_name: 'Helen', trs_last_name: 'Mirren', corrected_name: 'Dame Helen Mirren', trs_induction_status: 'Passed' },
  { trn: '0000021', trs_first_name: 'Peter', trs_last_name: 'Davison', trs_induction_status: 'RequiredToComplete', ect_payments_frozen_year: 2022, mentor_payments_frozen_year: 2022 },
  { trn: '0000022', trs_first_name: 'Roy', trs_last_name: 'Dotrice', **early_roll_out_mentor_attrs },
  { trn: '0000023', trs_first_name: 'Ichigo', trs_last_name: 'Kurosaki', trs_induction_status: 'InProgress' },
]

teachers.each do |attrs|
  FactoryBot.create(:teacher, *attrs[:traits], attrs.excluding(:traits)).tap do |teacher|
    describe_teacher(teacher)
  end
end
