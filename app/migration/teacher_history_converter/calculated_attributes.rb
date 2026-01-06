module TeacherHistoryConverter::CalculatedAttributes
  # Calculates the api_updated_at timestamp using ECF's ParticipantSerializer logic:
  # The max of participant_profiles.updated_at, user.updated_at,
  # participant_identities.updated_at, and induction_records.updated_at
  def participant_api_updated_at(ecf1_teacher_history:)
    timestamps = [ecf1_teacher_history.user.updated_at]

    if ecf1_teacher_history.ect.present?
      timestamps << ecf1_teacher_history.ect.updated_at
      timestamps.concat(ecf1_teacher_history.ect.induction_records(migration_mode:).map(&:updated_at))
    end

    if ecf1_teacher_history.mentor.present?
      timestamps << ecf1_teacher_history.mentor.updated_at
      timestamps.concat(ecf1_teacher_history.mentor.induction_records(migration_mode:).map(&:updated_at))
    end

    # participant_identities.updated_at is captured in user if needed
    timestamps.concat(ecf1_teacher_history.participant_identity_updated_ats || [])

    timestamps.compact.max
  end
end
