module Migration
  class InductionRecordExporter
    def run
      Migration::Base.connection.execute(query)
    end

  private

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
