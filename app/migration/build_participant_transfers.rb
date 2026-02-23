class BuildParticipantTransfers
  attr_reader :participant_profile

  def initialize(participant_profile:)
    @participant_profile = participant_profile
  end

  # returns a hash keyed on ecf1 lead_provider_id with either the:
  #  -  most recent leaving/joining induction_record.updated_at
  #  -  the user.updated_at if no leaving/joining
  #
  def transfers
    @transfers ||= build_transfers
  end

private

  def build_transfers
    traversed_induction_records = []
    participating_providers = []
    transfer_list = {}

    sorted_induction_records.each do |induction_record|
      participating_providers << induction_record.induction_programme.partnership&.lead_provider_id
      next unless induction_record.induction_status == "leaving"

      ## set leaving induction record and mark as traversed
      leaving_induction_record = induction_record
      traversed_induction_records << leaving_induction_record

      ## select possible joining induction record from remaining induction records
      remaining_induction_records = sorted_induction_records - traversed_induction_records
      joining_induction_record = select_joining_induction_record(leaving_induction_record:, remaining_induction_records:)
      traversed_induction_records << joining_induction_record if joining_induction_record.present?

      calc_most_recent_value(leaving_induction_record, transfer_list)
      calc_most_recent_value(joining_induction_record, transfer_list)
    end

    user_updated_at = participant_profile.teacher_profile.user.updated_at

    # if there are no leaving/joining records use the default user.updated_at timestamp
    (participating_providers.compact.uniq - transfer_list.keys).each do |lead_provider_id|
      transfer_list[lead_provider_id] = user_updated_at
    end

    transfer_list
  end

  def calc_most_recent_value(induction_record, transfer_list)
    return if induction_record.blank?

    lead_provider_id = induction_record.induction_programme.partnership&.lead_provider_id
    return unless lead_provider_id

    last_updated_at = [transfer_list[lead_provider_id], induction_record.updated_at].compact.max
    transfer_list[lead_provider_id] = last_updated_at
  end

  def select_joining_induction_record(leaving_induction_record:, remaining_induction_records:)
    joining_induction_record = nil

    remaining_induction_records.each do |candidate_induction_record|
      next unless candidate_induction_record.induction_status != "leaving" &&
        different_school?(leaving_induction_record:, candidate_induction_record:) &&
        candidate_induction_record.school_transfer

      joining_induction_record = candidate_induction_record
      break
    end

    joining_induction_record
  end

  def sorted_induction_records
    @sorted_induction_records ||= participant_profile.induction_records.order(:created_at)
  end

  def different_school?(leaving_induction_record:, candidate_induction_record:)
    candidate_induction_record.induction_programme.school_cohort.school_id != leaving_induction_record.induction_programme.school_cohort.school_id
  end
end
