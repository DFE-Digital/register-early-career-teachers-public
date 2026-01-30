ECF1TeacherHistory::InductionRecord = Struct.new(
  :induction_record_id,
  :start_date,
  :end_date,
  :created_at,
  :updated_at,
  :cohort_year,
  :school,
  :schedule_info,
  :preferred_identity_email,
  :mentor_profile_id,
  :training_status,
  :induction_status,
  :training_programme,
  :training_provider_info,
  :appropriate_body,
  keyword_init: true
) do
  using Migration::CompactWithIgnore

  def self.from_hash(hash)
    hash[:training_provider_info] = if (training_provider_info = hash[:training_provider_info]) && training_provider_info.present?
                                      ECF1TeacherHistory::TrainingProviderInfo.new(
                                        lead_provider_info: Types::LeadProviderInfo.new(**training_provider_info[:lead_provider]),
                                        delivery_partner_info: Types::DeliveryPartnerInfo.new(**training_provider_info[:delivery_partner]),
                                        cohort_year: training_provider_info[:cohort_year]
                                      )
                                    else
                                      :ignore
                                    end

    hash[:schedule_info] = if (schedule_info = hash[:schedule_info]) && schedule_info.present?
                             Types::ScheduleInfo.new(**schedule_info)
                           else
                             :ignore
                           end

    hash.compact_with_ignore!

    if (school = hash[:school])
      hash[:school] = Types::SchoolData.new(**school)
    end

    new(FactoryBot.attributes_for(:ecf1_teacher_history_induction_record_row, **hash))
  end

  def combination
    [school.urn, cohort_year, training_provider_info&.lead_provider_info&.name].join(": ")
  end

  def range
    start_date.to_date..end_date&.to_date
  end

  def range_covers_finish_but_not_start?(start, finish)
    range.cover?(finish) && !range.cover?(start)
  end

  def ongoing?
    end_date.nil?
  end
end
