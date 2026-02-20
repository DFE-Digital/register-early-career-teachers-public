class BuildParticipantTransfers
  attr_reader :participant_profile

  def initialize(participant_profile:)
    @participant_profile = participant_profile
    @leaving_induction_record = nil
    @joining_induction_record = nil
  end

  def transfers
    @transfers ||= build_transfers
  end

private

  def build_transfers
    transfer_list = []
    traversed_induction_records = []

    sorted_induction_records.each do |induction_record|
      next unless induction_record.induction_status == "leaving"

      ## set leaving induction record and mark as traversed
      leaving_induction_record = induction_record
      traversed_induction_records << leaving_induction_record

      ## select possible joining induction record from remaining induction records
      remaining_induction_records = sorted_induction_records - traversed_induction_records
      joining_induction_record = select_joining_induction_record(leaving_induction_record:, remaining_induction_records:)
      traversed_induction_records << joining_induction_record if joining_induction_record.present?

      transfer = {
        leaving: build_transfer_data(leaving_induction_record),
        joining: build_transfer_data(joining_induction_record)
      }

      ## add complete or incomplete transfer
      transfer_list << transfer
    end

    transfer_list
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

  def build_transfer_data(induction_record)
    return if induction_record.blank?

    training_provider_info = build_training_provider_info(induction_record.induction_programme.partnership)
    school_data = build_school_data(induction_record.induction_programme.school_cohort.school)

    Types::TransferData.new(training_provider_info:, school_data:, updated_at: induction_record.updated_at)
  end

  def build_training_provider_info(partnership)
    return if partnership.blank?

    lead_provider_info = Types::LeadProviderInfo.new(ecf1_id: partnership.lead_provider_id, name: partnership.lead_provider.name)
    delivery_partner_info = Types::DeliveryPartnerInfo.new(ecf1_id: partnership.delivery_partner_id, name: partnership.delivery_partner&.name)
    cohort_year = partnership.cohort.start_year

    ECF1TeacherHistory::TrainingProviderInfo.new(lead_provider_info:, delivery_partner_info:, cohort_year:)
  end

  def build_school_data(school)
    Types::SchoolData.new(urn: school.urn, name: school.name, school_type_name: school.school_type_name)
  end

  def sorted_induction_records
    @sorted_induction_records ||= participant_profile.induction_records.order(:created_at)
  end

  def different_school?(leaving_induction_record:, candidate_induction_record:)
    candidate_induction_record.induction_programme.school_cohort.school_id != leaving_induction_record.induction_programme.school_cohort.school_id
  end
end
