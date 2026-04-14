class ECF1TeacherHistory::DataPatcher
  PATCHES_PATH=Rails.root.join("app/migration/ecf1_teacher_history/data_patches.csv")

  attr_reader :data_patches

  def initialize(data_patches: CSV.table(PATCHES_PATH))
    @data_patches = data_patches
  end

  def apply_patches_to(ecf1_teacher_history)
    return ecf1_teacher_history unless has_patches?(ecf1_teacher_history)
    
    apply_profile_patches(ecf1_teacher_history.ect)
    apply_profile_patches(ecf1_teacher_history.mentor)

    ecf1_teacher_history
  end

  def has_patches?(ecf1_teacher_history)
    return false if data_patches.blank? || data_patches.empty?

    ids = [ecf1_teacher_history.ect&.participant_profile_id, ecf1_teacher_history.mentor&.participant_profile_id].compact
    return false if ids.empty?

    ids.any? do |participant_profile_id|
      data_patches.find { |row| row[:participant_profile_id] == participant_profile_id }
    end
  end

private

  def apply_profile_patches(profile)
    return if profile.blank?

    profile_patches(profile).each do |raw_patch|
      patch = prepare_patch(raw_patch.to_h)
      process_patch(profile, patch)
    end
  end

  def prepare_patch(raw_patch)
    parse_dates(raw_patch)

    {
      induction_record: extract_induction_record_changes(raw_patch),
      state: extract_state_changes(raw_patch),
    }
  end

  def extract_induction_record_changes(raw_patch)
    attrs = raw_patch.except(
      :participant_profile_id,
      :state_type,
      :state_reason,
      :state_cpd_lead_provider_id,
      :state_created_at
    ).compact

    return {} if attrs.empty?


    if attrs[:email].present?
      attrs[:preferred_identity_email] = attrs[:email]
    end

    if attrs[:school_transfer].present?
      attrs[:school_transfer] = ActiveModel::Type::Boolean.new.cast(attrs[:school_transfer])
    end

    if attrs[:ignore_training].present?
      attrs[:ignore_training] = ActiveModel::Type::Boolean.new.cast(attrs[:ignore_training])
    end

    attrs.except!(:email).compact
  end

  def extract_state_changes(raw_patch)
    attrs = raw_patch.slice(
      :state_type,
      :state_reason,
      :state_cpd_lead_provider_id,
      :state_created_at
    ).compact

    return nil if attrs.empty? || attrs.count != 4

    ECF1TeacherHistory::ProfileState.new(
      state: attrs[:state_type],
      reason: attrs[:state_reason],
      created_at: attrs[:state_created_at],
      cpd_lead_provider_id: attrs[:state_cpd_lead_provider_id]
    )
  end

  def parse_dates(attrs)
    %i[start_date end_date].each { |sym| attrs[sym] = Date.parse(attrs[sym]) if attrs[sym].present? && attrs[sym] != ":null" }
    %i[created_at updated_at state_created_at].each { |sym| attrs[sym] = Time.zone.parse(attrs[sym]) if attrs[sym].present? && attrs[sym] != ":null" }
  end

  def process_patch(profile, patch)
    induction_record_changes = patch[:induction_record]
    if induction_record_changes.present?
      induction_record_id = induction_record_changes[:induction_record_id]

      if induction_record_id.present?
        original_induction_record = profile.induction_records.find { |ir| ir.induction_record_id == induction_record_id }
        patch_induction_record(original_induction_record, induction_record_changes)
      end
    end

    state_record = patch[:state]
    if state_record.present?
      profile.states << state_record
      profile.states.sort_by!(&:created_at)
    end
  end

  def patch_induction_record(induction_record, changes)
    return if induction_record.blank?

    changes.except(:induction_record_id).each do |name, value|
      value = nil if value == ":null"
      induction_record.send("#{name}=", value)
    end
  end

  def profile_patches(profile)
    data_patches.find_all { |row| row[:participant_profile_id] == profile.participant_profile_id }
  end
end
