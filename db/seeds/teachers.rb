def describe_teacher(teacher)
  teacher_name = "#{teacher.trs_first_name} #{teacher.trs_last_name}"

  ero_status = if teacher.mentor_became_ineligible_for_funding_reason == "completed_during_early_roll_out"
                 Colourize.text("yes", :green)
               else
                 Colourize.text("no", :red)
               end

  payments_frozen =
    if teacher.ect_payments_frozen_year.present? && teacher.mentor_payments_frozen_year.present?
      Colourize.text("ECT/mentor", :green)
    elsif teacher.ect_payments_frozen_year.present?
      Colourize.text("ECT", :green)
    elsif teacher.mentor_payments_frozen_year.present?
      Colourize.text("mentor", :green)
    else
      Colourize.text("no", :red)
    end

  id_changes = if teacher.teacher_id_changes.present?
                 Colourize.text("yes", :green)
               else
                 Colourize.text("no", :red)
               end

  uplift =
    if teacher.ect_pupil_premium_uplift || teacher.ect_sparsity_uplift
      Colourize.text("yes", :green)
    else
      Colourize.text("no", :red)
    end

  print_seed_info("#{teacher_name} (early roll out mentor: #{ero_status}, payments frozen: #{payments_frozen}, id changes: #{id_changes}, uplift: #{uplift})", indent: 2)
end

early_roll_out_mentor_attrs = {
  mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out",
  mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19)
}

uplift_attrs = {
  ect_sparsity_uplift: true,
  ect_pupil_premium_uplift: true,
}

teachers = [
  # Edge cases where TRS records change after a teacher record exists in the database
  { trn: "3002962", trs_first_name: "Maxx", trs_last_name: "Test", trs_induction_status: "None", corrected_name: "Maximus Testicus (deactivated)" },
  { trn: "3013021", trs_first_name: "Dave", trs_last_name: "Teacher", trs_induction_status: "None", corrected_name: "Substitutus Magister (merged)" },

  # NB: DO NOT use TRNs from TRS because attributes like name will change when refreshed
  { trn: "0000001", trs_first_name: "Stephen", trs_last_name: "Griddle", trs_induction_status: "InProgress" },
  { trn: "0000002", trs_first_name: "Dominic", trs_last_name: "East", trs_induction_status: "InProgress" },
  { trn: "0000003", trs_first_name: "Hugh", trs_last_name: "Stipend",  trs_induction_status: "Failed", trs_induction_completed_date: Date.new(2023, 6, 30) },
  { trn: "0000004", trs_first_name: "Emma", trs_last_name: "Thompson", trs_induction_status: "InProgress", **uplift_attrs },
  { trn: "0000005", trs_first_name: "Kate", trs_last_name: "Winslet",  trs_induction_status: "Passed", trs_induction_completed_date: Date.new(2023, 6, 30), **uplift_attrs },
  { trn: "0000006", trs_first_name: "Alan", trs_last_name: "Rickman",  trs_induction_status: "RequiredToComplete" },
  { trn: "0000007", trs_first_name: "Colin", trs_last_name: "Firth",  trs_induction_status: "Exempt" },
  { trn: "0000008", trs_first_name: "Robert", trs_last_name: "Webb",  **early_roll_out_mentor_attrs },
  { trn: "0000009", trs_first_name: "David", trs_last_name: "Mitchell", **early_roll_out_mentor_attrs },
  { trn: "0000010", trs_first_name: "Harriet", trs_last_name: "Walter", trs_induction_status: "InProgress", **early_roll_out_mentor_attrs },
  { trn: "0000011", trs_first_name: "Hugh", trs_last_name: "Laurie", trs_induction_status: "Passed", trs_induction_completed_date: Date.new(2023, 6, 30), **early_roll_out_mentor_attrs },
  { trn: "0000013", trs_first_name: "Stephen", trs_last_name: "Fry", trs_induction_status: "RequiredToComplete", id_changed_from_trn: "0000001", traits: %i[with_teacher_id_change] },
  { trn: "0000014", trs_first_name: "Dominic", trs_last_name: "West", trs_induction_status: "InProgress", id_changed_from_trn: "0000002", traits: %i[with_teacher_id_change] },
  { trn: "0000012", trs_first_name: "Hugh", trs_last_name: "Grant", trs_induction_status: "Failed", trs_induction_completed_date: Date.new(2023, 6, 30), id_changed_from_trn: "0000003", traits: %i[with_teacher_id_change] },
  { trn: "0000015", trs_first_name: "André", trs_last_name: "Roussimoff", trs_induction_status: "FailedInWales" },
  { trn: "0000016", trs_first_name: "Imogen", trs_last_name: "Stubbs", trs_induction_status: "InProgress", ect_payments_frozen_year: 2021 },
  { trn: "0000017", trs_first_name: "Gemma", trs_last_name: "Jones", trs_induction_status: "InProgress" },
  { trn: "0000018", trs_first_name: "Anthony", trs_last_name: "Hopkins", trs_induction_status: "Exempt", mentor_payments_frozen_year: 2021 },
  { trn: "0000019", trs_first_name: "John", trs_last_name: "Withers", corrected_name: "Old Man Withers", trs_induction_status: "Failed", trs_induction_completed_date: Date.new(2023, 6, 30) },
  { trn: "0000020", trs_first_name: "Helen", trs_last_name: "Mirren", corrected_name: "Dame Helen Mirren", trs_induction_status: "Passed", trs_induction_completed_date: Date.new(2023, 6, 30) },
  { trn: "0000021", trs_first_name: "Peter", trs_last_name: "Davison", trs_induction_status: "RequiredToComplete", ect_payments_frozen_year: 2022, mentor_payments_frozen_year: 2022 },
  { trn: "0000022", trs_first_name: "Roy", trs_last_name: "Dotrice", **early_roll_out_mentor_attrs },
  # no QTS needed for AB check-data scenarios
  { trn: "0000024", trs_first_name: "Alastair", trs_last_name: "Sim", trs_induction_status: "InProgress", trs_qts_awarded_on: nil },
  { trn: "0000025", trs_first_name: "Margaret", trs_last_name: "Rutherford", trs_induction_status: "InProgress" },
  { trn: "0000026", trs_first_name: "Terry", trs_last_name: "Thomas", trs_induction_status: "InProgress" },
  { trn: "0000027", trs_first_name: "Sid", trs_last_name: "James", trs_induction_status: "InProgress" },
  { trn: "0000028", trs_first_name: "Joan", trs_last_name: "Sims", trs_induction_status: "InProgress" },
  { trn: "0000029", trs_first_name: "Hattie", trs_last_name: "Jacques", trs_induction_status: "InProgress" },
  { trn: "0000030", trs_first_name: "Jane", trs_last_name: "Smith", trs_induction_status: "InProgress" },
  { trn: "0000031", trs_first_name: "Joyce", trs_last_name: "Grenfell", trs_induction_status: "InProgress" },
  { trn: "0000032", trs_first_name: "George", trs_last_name: "Cole", trs_induction_status: "InProgress" },
  { trn: "0000033", trs_first_name: "Frankie", trs_last_name: "Howard", trs_induction_status: "InProgress" },
  { trn: "0000034", trs_first_name: "Naruto", trs_last_name: "Uzumaki", trs_induction_status: "InProgress" },
]

teachers.each do |attrs|
  trn = attrs.fetch(:trn)

  teacher = Teacher.find_or_initialize_by(trn:)

  teacher_attributes = attrs.excluding(:traits, :id_changed_from_trn).except(:trn)

  # Set default QTS date (must be before start dates in teacher_histories.rb) unless explicitly defined
  unless attrs.key?(:trs_qts_awarded_on)
    teacher_attributes[:trs_qts_awarded_on] = Date.new(2021, 1, 1)
  end

  teacher.assign_attributes(teacher_attributes)
  teacher.save!

  if attrs[:traits]&.include?(:with_teacher_id_change)
    from_trn = attrs.fetch(:id_changed_from_trn)

    from_teacher =
      Teacher.find_by(trn: from_trn) ||
      Teacher.create!(
        trn: from_trn,
        trs_first_name: teacher.trs_first_name,
        trs_last_name: teacher.trs_last_name
      )

    TeacherIdChange.find_or_create_by!(
      teacher_id: teacher.id,
      api_from_teacher_id: from_teacher.api_id,
      api_to_teacher_id: teacher.api_id
    )
  end

  describe_teacher(teacher)
end
