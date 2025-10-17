module Migration
  class InductionRecordExporter
    def run
      Migration::Base.connection.execute(query)
    end

    def stream_csv_to(output_stream)
      output_stream.write CSV.generate_line(csv_headers)
      ar_query.limit(10).find_each(batch_size: 2000) do |induction_record|
        output_stream.write CSV.generate_line(csv_row(induction_record))
      end
    end

  private

    def csv_headers
      attributes.map(&:humanize)
    end

    def attributes
      %w[id start_date end_date right_way_round duration training_status school_transfer induction_record_creaated ect_participant_profile_id mentor_participant_profile_id urn challenged lead_provider_name].freeze
    end

    def csv_row(induction_record)
      [
        induction_record.id,
        induction_record.start_date.to_date,
        induction_record.end_date&.to_date,
        right_way_round?(induction_record),
        duration_of(induction_record),
        induction_record.training_status,
        induction_record.school_transfer,
        induction_record.created_at.to_date,
        ect_profile_id(induction_record),
        mentor_profile_id(induction_record),
        induction_record.induction_programme.school_cohort.school.urn,
        challenged?(induction_record),
        induction_record.induction_programme&.partnership&.lead_provider&.name,
      ]
    end

    def ect_profile_id(induction_record)
      induction_record.participant_profile_id if induction_record.participant_profile.type == "ParticipantProfile::ECT"
    end

    def mentor_profile_id(induction_record)
      induction_record.participant_profile_id if induction_record.participant_profile.type == "ParticipantProfile::Mentor"
    end

    def challenged?(induction_record)
      return nil unless induction_record.induction_programme&.partnership.present?

      induction_record.induction_programme.partnership.challenged_at.present?
    end

    def right_way_round?(induction_record)
      return true if induction_record.end_date.blank?
      induction_record.start_date < induction_record.end_date
    end

    def duration_of(induction_record)
      return nil if induction_record.end_date.blank?

      (induction_record.end_date.to_date - induction_record.start_date.to_date).to_i
    end

    def ar_query
      InductionRecord.eager_load(:participant_profile, :preferred_identity, induction_programme: { school_cohort: :school, partnership: :lead_provider } ).order(:participant_profile_id)
    end

    def query
      <<~SQL
        with
          ect_info as (
            select u.id as user_id,
                  pp.id as participant_profile_id,
                  tp.trn
            from users u
            inner join participant_identities pi on u.id = pi.user_id
            inner join participant_profiles pp on pi.id = pp.participant_identity_id
            inner join teacher_profiles tp on u.id = tp.user_id
            where pp.type = 'ParticipantProfile::ECT'
          ),
          mentor_info as (
            select u.id as user_id,
                  pp.id as participant_profile_id,
                  tp.trn
            from users u
            inner join participant_identities pi on u.id = pi.user_id
            inner join participant_profiles pp on pi.id = pp.participant_identity_id
            inner join teacher_profiles tp on u.id = tp.user_id
            where pp.type = 'ParticipantProfile::Mentor'
          ),
          school_and_induction_programme_info as (
            select s.urn,
                  ip.id as induction_programme_id,
                  p.challenged_at,
                  case when (p.challenged_at is null) then false
                  else true
                  end as challenged,
                  lp.name as lead_provider_name
            from schools s
            inner join school_cohorts sc on s.id = sc.school_id
            inner join induction_programmes ip on ip.school_cohort_id = sc.id
            inner join partnerships p on ip.partnership_id = p.id
            inner join lead_providers lp on p.lead_provider_id = lp.id
          )

        select ir.id as induction_record_id,
              ir.start_date::date,
              ir.end_date::date,
              case
              when ir.end_date::date is null then true
              when ir.start_date::date < ir.end_date::date then true
              else false end as right_way_round,
              ir.end_date::date - ir.start_date::date as duration,
              ir.training_status,
              ir.school_transfer,
              ir.created_at::date as induction_record_created,
              ei.participant_profile_id as ect_particiapnt_profile_id,
              mi.participant_profile_id as mentor_particiapnt_profile_id,
              sipi.urn,
              sipi.challenged,
              sipi.lead_provider_name
        from induction_records ir
        left outer join ect_info ei on ir.participant_profile_id = ei.participant_profile_id
        left outer join mentor_info mi on ir.mentor_profile_id = mi.participant_profile_id
        left outer join school_and_induction_programme_info sipi on ir.induction_programme_id = sipi.induction_programme_id
        ;
      SQL
    end
  end
end
