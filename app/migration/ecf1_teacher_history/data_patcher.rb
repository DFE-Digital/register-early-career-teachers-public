class ECF1TeacherHistory::DataPatcher
  PATCHES_PATH=Rails.root.join("app/migration/ecf1_teacher_history/data_patches.csv")

  def initialize(csv_file: PATCHES_PATH)
    @csv_file = csv_file
  end

  def apply_patches_to(ecf1_teacher_history)
    return ecf1_teacher_history unless has_patches?(ecf1_teacher_history)
    
    apply_profile_patches(ecf1_teacher_history.ect)
    apply_profile_patches(ecf1_teacher_history.mentor)

    ecf1_teacher_history
  end

  def has_patches?(ecf1_teacher_history)
    ids = [ecf1_teacher_history.ect&.participant_profile_id, ecf1_teacher_history.mentor&.participant_profile_id].compact
    return false if ids.empty?

    ids.any? do |participant_profile_id|
      patches.find { |row| row[:participant_profile_id] == participant_profile_id }
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

    parse_dates(attrs)
    
    lead_provider_info = if attrs[:lead_provider_id].present? && attrs[:lead_provider_name].present?
      Types::LeadProviderInfo.new(ecf1_id: attrs[:lead_provider_id], name: attrs[:lead_provider_name])
    end

    delivery_partner_info = if attrs[:delivery_partner_id].present? && attrs[:delivery_partner_name].present?
      Types::DeliveryPartnerInfo.new(api_id: attrs[:_delivery_partner_id], name: attrs[:_delivery_partner_name])
    end

    if attrs[:cohort_year].present? && lead_provider_info.present? && delivery_partner.present?
      attrs[:training_provider_info] = TrainingProviderInfo.new(lead_provider_info:,
                                                                delivery_partner_info:,
                                                                cohort_year: attrs[:cohort_year])
    end

    attrs.except!(:lead_provider_id, :lead_provider_name, :delivery_partner_id, :delivery_partner_name).compact
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
      created_at: Time.zone.parse(attrs[:state_created_at]),
      cpd_lead_provider_id: attrs[:state_cpd_lead_provider_id]
    )
  end

  def parse_dates(attrs)
    %i[start_date end_date].each { |sym| attrs[sym] = Date.parse(attrs[sym]) if attrs[sym].present? }
    %i[created_at updated_at].each { |sym| attrs[sym] = Time.zone.parse(attrs[sym]) if attrs[sym].present? }
  end

  def process_patch(profile, patch)
    induction_record_id = patch[:induction_record_id]
    if induction_record_id.present?
      prepped_patch = prepare_patch(patch)
      induction_record = profile.induction_records.find { |ir| ir.induction_record_id == induction_record_id }
      patch_induction_record(induction_record, patch)
    end
  end

  def patch_induction_record(induction_record, patch)
    return if induction_record.blank?

    if patch[:start_date].present?
      induction_record.start_date = Date.parse(patch[:start_date])
    end
  end

  def profile_patches(profile)
    patches.find_all { |row| row[:participant_profile_id] == profile.participant_profile_id }
  end

  def patches
    @patches ||= CSV.table(@csv_file)
  end
end
