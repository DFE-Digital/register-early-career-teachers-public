module API
  class MentorshipsReactor < Reactor
    include LeadProviderReactions

    def reacts_to?(event) = event.mentorship_period_id.present? || event.teacher_id.present?

    def react_to!(event)
      MentorshipPeriod.affected_by(event).find_each do |mentorship_period|
        mentorship_period.with_lock do
          emit_reaction_events!(resource: mentorship_period, in_reaction_to: event)
        end
      end
    end

  private

    def payload_for(resource:, **)
      mentor = resource.mentor
      mentee = resource.mentee

      {
        started_on: resource.started_on,
        finished_on: resource.finished_on,
        school_urn: mentee.school.urn,
        ect_trn: mentee.teacher.trn,
        mentor_trn: mentor.teacher.trn,
        mentor_email: mentor.email,
        mentor_full_name: mentor.teacher.full_name,
      }.as_json
    end

    def record_reaction_event!(action:, resource:, lead_provider:, in_reaction_to:, payload:)
      Events::Record.record_api_mentorship_event!(action:, lead_provider:, mentorship_period: resource, in_reaction_to:, payload:)
    end
  end
end
