module Events
  class InvalidAuthor < StandardError; end
  class NotPersistedRecord < StandardError; end
  class NoInductionPeriod < StandardError; end

  class Record
    attr_reader :author,
                :event_type,
                :heading,
                :body,
                :happened_at,
                :school,
                :induction_period,
                :teacher,
                :appropriate_body,
                :induction_extension,
                :ect_at_school_period,
                :mentor_at_school_period,
                :training_period,
                :mentorship_period,
                :schedule,
                :school_partnership,
                :lead_provider,
                :delivery_partner,
                :pending_induction_submission_batch,
                :active_lead_provider,
                :lead_provider_delivery_partnership,
                :statement,
                :statement_adjustment,
                :user,
                :modifications,
                :metadata,
                :zendesk_ticket_id

    def initialize(
      author:,
      event_type:,
      heading:,
      happened_at:,
      body: nil,
      school: nil,
      induction_period: nil,
      teacher: nil,
      appropriate_body: nil,
      induction_extension: nil,
      ect_at_school_period: nil,
      mentor_at_school_period: nil,
      training_period: nil,
      mentorship_period: nil,
      schedule: nil,
      school_partnership: nil,
      lead_provider: nil,
      delivery_partner: nil,
      pending_induction_submission_batch: nil,
      active_lead_provider: nil,
      lead_provider_delivery_partnership: nil,
      statement: nil,
      statement_adjustment: nil,
      user: nil,
      modifications: nil,
      metadata: nil,
      zendesk_ticket_id: nil
    )
      @author = author
      @event_type = event_type
      @heading = heading
      @body = body
      @happened_at = happened_at
      @school = school
      @induction_period = induction_period
      @teacher = teacher
      @appropriate_body = appropriate_body
      @induction_extension = induction_extension
      @ect_at_school_period = ect_at_school_period
      @mentor_at_school_period = mentor_at_school_period
      @training_period = training_period
      @mentorship_period = mentorship_period
      @schedule = schedule
      @school_partnership = school_partnership
      @lead_provider = lead_provider
      @delivery_partner = delivery_partner
      @pending_induction_submission_batch = pending_induction_submission_batch
      @active_lead_provider = active_lead_provider
      @lead_provider_delivery_partnership = lead_provider_delivery_partnership
      @statement = statement
      @statement_adjustment = statement_adjustment
      @user = user
      @modifications = DescribeModifications.new(modifications).describe
      @metadata = metadata || modifications
      @zendesk_ticket_id = zendesk_ticket_id
    end

    def record_event!
      check_relationship_attributes_are_persisted
      RecordEventJob.perform_later(**attributes)
    end

    # Induction Period Events

    def self.record_induction_period_opened_event!(author:, appropriate_body:, induction_period:, teacher:, modifications:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :induction_period_opened
      happened_at = induction_period.started_on
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was claimed by #{appropriate_body.name}"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:, modifications:).record_event!
    end

    def self.record_induction_period_closed_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :induction_period_closed
      happened_at = induction_period.finished_on
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was released by #{appropriate_body.name}"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_induction_period_updated_event!(author:, modifications:, induction_period:, teacher:, appropriate_body:, happened_at: Time.zone.now)
      event_type = :induction_period_updated
      heading = 'Induction period updated by admin' if author.dfe_user?
      heading = 'Induction period updated by appropriate body' if author.appropriate_body_user?

      new(event_type:, modifications:, author:, appropriate_body:, induction_period:, teacher:, heading:, happened_at:).record_event!
    end

    def self.record_induction_period_deleted_event!(author:, modifications:, teacher:, appropriate_body:, body: nil, zendesk_ticket_id: nil, happened_at: Time.zone.now)
      event_type = :induction_period_deleted
      heading = 'Induction period deleted by admin'

      new(event_type:, modifications:, author:, appropriate_body:, teacher:, heading:, happened_at:, body:, zendesk_ticket_id:).record_event!
    end

    # Teacher Status Events

    def self.record_teacher_passes_induction_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :teacher_passes_induction
      happened_at = induction_period.finished_on
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} passed induction"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_teacher_fails_induction_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :teacher_fails_induction
      happened_at = induction_period.finished_on
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} failed induction"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_admin_passes_teacher_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :teacher_passes_induction
      heading = "#{Teachers::Name.new(teacher).full_name} passed induction (admin)"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_admin_fails_teacher_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :teacher_fails_induction
      heading = "#{Teachers::Name.new(teacher).full_name} failed induction (admin)"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_teacher_induction_status_reset_event!(author:, appropriate_body:, teacher:, happened_at: Time.zone.now)
      event_type = :teacher_induction_status_reset
      heading = "#{Teachers::Name.new(teacher).full_name} was unclaimed"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    # Teacher TRS Events

    def self.teacher_name_changed_in_trs_event!(old_name:, new_name:, author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_name_updated_by_trs
      heading = TransitionDescription.for("name", from: old_name, to: new_name)

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_induction_status_changed_in_trs_event!(old_induction_status:, new_induction_status:, author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_trs_induction_status_updated
      heading = TransitionDescription.for("induction_status", from: old_induction_status, to: new_induction_status)

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_imported_from_trs_event!(author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_imported_from_trs
      heading = "Imported from TRS"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_trs_attributes_updated_event!(author:, teacher:, modifications:, happened_at: Time.zone.now)
      event_type = :teacher_trs_attributes_updated
      heading = "TRS attributes updated"

      new(event_type:, author:, modifications:, teacher:, heading:, happened_at:).record_event!
    end

    def self.record_teacher_trs_deactivated_event!(author:, teacher:, happened_at: Time.zone.now)
      event_type = :teacher_trs_deactivated
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was deactivated in TRS"
      body = "TRS API returned 410 so the record was marked as deactivated"

      new(event_type:, author:, teacher:, heading:, body:, happened_at:).record_event!
    end

    def self.record_teacher_trs_induction_start_date_updated_event!(author:, teacher:, appropriate_body:, induction_period:, happened_at: Time.zone.now)
      event_type = :teacher_trs_induction_start_date_updated
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction start date was updated"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_teacher_trs_induction_end_date_updated_event!(author:, teacher:, appropriate_body:, induction_period:, happened_at: Time.zone.now)
      event_type = :teacher_trs_induction_end_date_updated
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction end date was updated"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    # Induction Extension Events

    def self.record_induction_extension_created_event!(author:, appropriate_body:, teacher:, induction_extension:, modifications:, happened_at: Time.zone.now)
      event_type = :induction_extension_created
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction extended by #{induction_extension.number_of_terms} terms"

      new(event_type:, author:, appropriate_body:, teacher:, induction_extension:, modifications:, heading:, happened_at:).record_event!
    end

    def self.record_induction_extension_updated_event!(author:, appropriate_body:, teacher:, induction_extension:, modifications:, happened_at: Time.zone.now)
      event_type = :induction_extension_updated
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction extended by #{induction_extension.number_of_terms} terms"

      new(event_type:, author:, appropriate_body:, teacher:, induction_extension:, modifications:, heading:, happened_at:).record_event!
    end

    def self.record_induction_extension_deleted_event!(author:, appropriate_body:, teacher:, number_of_terms:, happened_at: Time.zone.now)
      event_type = :induction_extension_deleted
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction extension of #{number_of_terms} terms was deleted"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.record_induction_period_reopened_event!(author:, induction_period:, modifications:, teacher:, appropriate_body:, body:, zendesk_ticket_id:)
      event_type = :induction_period_reopened
      happened_at = Time.zone.now

      heading = 'Induction period reopened'

      new(event_type:, induction_period:, modifications:, author:, appropriate_body:, teacher:, heading:, happened_at:, body:, zendesk_ticket_id:).record_event!
    end

    # ECT and mentor events

    def self.record_teacher_registered_as_mentor_event!(author:, mentor_at_school_period:, teacher:, school:, training_period:, lead_provider:, happened_at: Time.zone.now)
      event_type = :teacher_registered_as_mentor
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was registered as a mentor at #{school.name}"

      new(event_type:, author:, heading:, mentor_at_school_period:, teacher:, school:, training_period:, lead_provider:, happened_at:).record_event!
    end

    def self.record_teacher_registered_as_ect_event!(author:, ect_at_school_period:, teacher:, school:, training_period:, happened_at: Time.zone.now)
      event_type = :teacher_registered_as_ect
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was registered as an ECT at #{school.name}"
      schedule = training_period.schedule

      new(event_type:, author:, heading:, ect_at_school_period:, teacher:, school:, training_period:, schedule:, happened_at:).record_event!
    end

    def self.record_teacher_left_school_as_ect!(author:, ect_at_school_period:, teacher:, school:, training_period:, happened_at:)
      event_type = :teacher_left_school_as_ect
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} left #{school.name}"

      new(event_type:, author:, heading:, ect_at_school_period:, teacher:, school:, training_period:, happened_at:).record_event!
    end

    def self.record_teacher_starts_training_period_event!(author:, training_period:, ect_at_school_period:, mentor_at_school_period:, teacher:, school:, happened_at:)
      if ect_at_school_period.present? && mentor_at_school_period.present?
        fail(ArgumentError, "either ect_at_school_period or mentor_at_school_period permitted, not both")
      end

      if ect_at_school_period.nil? && mentor_at_school_period.nil?
        fail(ArgumentError, "either ect_at_school_period or mentor_at_school_period is required")
      end

      event_type = :teacher_starts_training_period
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = (ect_at_school_period.present?) ? 'ECT' : 'mentor'
      heading = "#{teacher_name} started a new #{training_type} training period"

      new(event_type:, author:, heading:, training_period:, ect_at_school_period:, mentor_at_school_period:, school:, teacher:, happened_at:).record_event!
    end

    def self.record_teacher_finishes_training_period_event!(author:, training_period:, ect_at_school_period:, mentor_at_school_period:, teacher:, school:, happened_at:)
      if ect_at_school_period.present? && mentor_at_school_period.present?
        fail(ArgumentError, "either ect_at_school_period or mentor_at_school_period permitted, not both")
      end

      if ect_at_school_period.nil? && mentor_at_school_period.nil?
        fail(ArgumentError, "either ect_at_school_period or mentor_at_school_period is required")
      end

      event_type = :teacher_finishes_training_period
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = (ect_at_school_period.present?) ? 'ECT' : 'mentor'
      heading = "#{teacher_name} finished their #{training_type} training period"

      new(event_type:, author:, heading:, training_period:, ect_at_school_period:, mentor_at_school_period:, school:, teacher:, happened_at:).record_event!
    end

    def self.record_teacher_starts_mentoring_event!(author:, mentor:, mentee:, mentor_at_school_period:, mentorship_period:, school:, happened_at: Time.zone.now)
      event_type = :teacher_starts_mentoring
      mentor_name = Teachers::Name.new(mentor).full_name
      mentee_name = Teachers::Name.new(mentee).full_name
      heading = "#{mentor_name} started mentoring #{mentee_name}"
      metadata = { mentor_id: mentor.id, mentee_id: mentee.id }

      new(event_type:, author:, heading:, mentorship_period:, mentor_at_school_period:, teacher: mentor, school:, metadata:, happened_at:).record_event!
    end

    def self.record_teacher_starts_being_mentored_event!(author:, mentor:, mentee:, ect_at_school_period:, mentorship_period:, school:, happened_at: Time.zone.now)
      event_type = :teacher_starts_being_mentored
      mentor_name = Teachers::Name.new(mentor).full_name
      mentee_name = Teachers::Name.new(mentee).full_name
      heading = "#{mentee_name} is being mentored by #{mentor_name}"
      metadata = { mentor_id: mentor.id, mentee_id: mentee.id }

      new(event_type:, author:, heading:, mentorship_period:, ect_at_school_period:, teacher: mentee, school:, metadata:, happened_at:).record_event!
    end

    def self.record_teacher_finishes_mentoring_event!(author:, mentor:, mentee:, mentor_at_school_period:, mentorship_period:, school:, happened_at:)
      event_type = :teacher_finishes_mentoring
      mentor_name = Teachers::Name.new(mentor).full_name
      mentee_name = Teachers::Name.new(mentee).full_name
      heading = "#{mentor_name} finished mentoring #{mentee_name}"
      metadata = { mentor_id: mentor.id, mentee_id: mentee.id }

      new(event_type:, author:, heading:, mentorship_period:, mentor_at_school_period:, teacher: mentor, school:, metadata:, happened_at:).record_event!
    end

    def self.record_teacher_finishes_being_mentored_event!(author:, mentor:, mentee:, ect_at_school_period:, mentorship_period:, school:, happened_at:)
      event_type = :teacher_finishes_being_mentored
      mentor_name = Teachers::Name.new(mentor).full_name
      mentee_name = Teachers::Name.new(mentee).full_name
      heading = "#{mentee_name} is no longer being mentored by #{mentor_name}"
      metadata = { mentor_id: mentor.id, mentee_id: mentee.id }

      new(event_type:, author:, heading:, mentorship_period:, ect_at_school_period:, teacher: mentee, school:, metadata:, happened_at:).record_event!
    end

    def self.record_teacher_email_updated_event!(old_email:, new_email:, author:, school:, teacher:, happened_at:, ect_at_school_period: nil, mentor_at_school_period: nil)
      event_type = :teacher_email_address_updated
      heading = TransitionDescription.for("email address", from: old_email, to: new_email)

      new(event_type:, author:, heading:, ect_at_school_period:, mentor_at_school_period:, school:, teacher:, happened_at:).record_event!
    end

    def self.record_teacher_working_pattern_updated_event!(old_working_pattern:, new_working_pattern:, author:, ect_at_school_period:, school:, teacher:, happened_at:)
      event_type = :teacher_working_pattern_updated
      heading = TransitionDescription.for(
        "working pattern",
        from: old_working_pattern.humanize.downcase,
        to: new_working_pattern.humanize.downcase
      )

      new(event_type:, author:, heading:, ect_at_school_period:, school:, teacher:, happened_at:).record_event!
    end

    def self.record_teacher_training_programme_updated_event!(old_training_programme:, new_training_programme:, author:, ect_at_school_period:, school:, teacher:, happened_at:)
      event_type = :teacher_training_programme_updated
      heading = TransitionDescription.for(
        "training programme",
        from: old_training_programme.humanize.downcase,
        to: new_training_programme.humanize.downcase
      )

      new(event_type:, author:, heading:, ect_at_school_period:, school:, teacher:, happened_at:).record_event!
    end

    # Records a change in lead provider for either an ECT or mentor, depending which period is given
    def self.record_teacher_training_lead_provider_updated_event!(old_lead_provider_name:, new_lead_provider_name:, author:, ect_at_school_period:, mentor_at_school_period:, school:, teacher:, happened_at:)
      event_type = :teacher_training_lead_provider_updated
      heading = TransitionDescription.for(
        "lead provider",
        from: old_lead_provider_name,
        to: new_lead_provider_name
      )

      new(event_type:, author:, heading:, ect_at_school_period:, mentor_at_school_period:, school:, teacher:, happened_at:).record_event!
    end

    def self.record_teacher_left_school_as_mentor!(author:, mentor_at_school_period:, teacher:, school:, happened_at:)
      event_type = :teacher_left_school_as_mentor
      teacher_name = Teachers::Name.new(teacher).full_name
      school_name = school.name
      heading = "#{teacher_name} left #{school_name}"

      new(event_type:, author:, heading:, mentor_at_school_period:, teacher:, school:, happened_at:).record_event!
    end

    def self.record_teacher_training_period_deferred_event!(author:, training_period:, teacher:, lead_provider:, modifications:, happened_at: Time.zone.now)
      event_type = :teacher_defers_training_period
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = (training_period.for_ect?) ? 'ECT' : 'mentor'
      heading = "#{teacher_name}’s #{training_type} training period was deferred by #{lead_provider.name}"

      new(event_type:, author:, heading:, training_period:, teacher:, lead_provider:, modifications:, happened_at:).record_event!
    end

    def self.record_teacher_training_period_withdrawn_event!(author:, training_period:, teacher:, lead_provider:, modifications:, happened_at: Time.zone.now)
      event_type = :teacher_withdraws_training_period
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = (training_period.for_ect?) ? 'ECT' : 'mentor'
      heading = "#{teacher_name}’s #{training_type} training period was withdrawn by #{lead_provider.name}"

      new(event_type:, author:, heading:, training_period:, teacher:, lead_provider:, modifications:, happened_at:).record_event!
    end

    def self.record_teacher_training_period_resumed_event!(author:, training_period:, teacher:, lead_provider:, metadata:, happened_at: Time.zone.now)
      event_type = :teacher_resumes_training_period
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = (training_period.for_ect?) ? 'ECT' : 'mentor'
      heading = "#{teacher_name}’s #{training_type} training period was resumed by #{lead_provider.name}"

      new(event_type:, author:, heading:, training_period:, teacher:, lead_provider:, metadata:, happened_at:).record_event!
    end

    def self.record_teacher_schedule_assigned_to_training_period!(author:, training_period:, teacher:, schedule:, happened_at: Time.zone.now)
      event_type = :teacher_schedule_assigned_to_training_period
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = (training_period.for_ect?) ? 'ECT' : 'mentor'
      heading = "#{teacher_name}’s #{training_type} training period schedule was set to #{schedule.identifier} for #{schedule.contract_period_year}"

      new(event_type:, author:, heading:, training_period:, teacher:, schedule:, happened_at:).record_event!
    end

    def self.record_training_period_assigned_to_school_partnership_event!(
      author:,
      training_period:,
      ect_at_school_period:,
      mentor_at_school_period:,
      school_partnership:,
      lead_provider:,
      delivery_partner:,
      school:,
      teacher:,
      happened_at: Time.zone.now
    )
      if ect_at_school_period.present? && mentor_at_school_period.present?
        fail(ArgumentError, 'either ect_at_school_period or mentor_at_school_period permitted, not both')
      end

      if ect_at_school_period.nil? && mentor_at_school_period.nil?
        fail(ArgumentError, 'either ect_at_school_period or mentor_at_school_period is required')
      end

      event_type = :training_period_assigned_to_school_partnership
      teacher_name = Teachers::Name.new(teacher).full_name
      training_type = ect_at_school_period.present? ? 'ECT' : 'mentor'
      heading = "#{teacher_name}’s #{training_type} training period was assigned to a school partnership"

      new(
        event_type:,
        author:,
        heading:,
        training_period:,
        ect_at_school_period:,
        mentor_at_school_period:,
        school_partnership:,
        lead_provider:,
        delivery_partner:,
        school:,
        teacher:,
        happened_at:
      ).record_event!
    end

    def self.record_teacher_set_funding_eligibility_event!(author:, teacher:, happened_at:, modifications:)
      event_type = :teacher_funding_eligibility_set
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s funding eligibility was set"

      new(event_type:, author:, heading:, teacher:, happened_at:, modifications:).record_event!
    end

    # Bulk Upload Events

    def self.record_bulk_upload_started_event!(author:, batch:)
      event_type = :bulk_upload_started
      heading = "#{batch.appropriate_body.name} started a bulk #{batch.batch_type}"

      new(event_type:, author:, appropriate_body: batch.appropriate_body, pending_induction_submission_batch: batch, heading:, happened_at: Time.zone.now).record_event!
    end

    def self.record_bulk_upload_completed_event!(author:, batch:)
      event_type = :bulk_upload_completed
      heading = "#{batch.appropriate_body.name} completed a bulk #{batch.batch_type}"

      new(event_type:, author:, appropriate_body: batch.appropriate_body, pending_induction_submission_batch: batch, heading:, happened_at: Time.zone.now).record_event!
    end

    # API Token Events

    def self.record_lead_provider_api_token_created_event!(author:, api_token:)
      event_type = :lead_provider_api_token_created
      lead_provider = api_token.lead_provider
      heading = "An API token was created for lead provider: #{lead_provider.name}"
      metadata = { description: api_token.description }

      new(event_type:, author:, heading:, lead_provider:, happened_at: Time.zone.now, metadata:).record_event!
    end

    def self.record_lead_provider_api_token_revoked_event!(author:, api_token:)
      event_type = :lead_provider_api_token_revoked
      lead_provider = api_token.lead_provider
      heading = "An API token was revoked for lead provider: #{lead_provider.name}"
      metadata = { description: api_token.description }

      new(event_type:, author:, heading:, lead_provider:, happened_at: Time.zone.now, metadata:).record_event!
    end

    # School Partnership Events

    def self.record_school_partnership_created_event!(author:, school_partnership:)
      event_type = :school_partnership_created
      school = school_partnership.school
      delivery_partner = school_partnership.delivery_partner
      lead_provider = school_partnership.lead_provider
      contract_period = school_partnership.contract_period
      heading = "#{school.name} partnered with #{delivery_partner.name} (via #{lead_provider.name}) for #{contract_period.year}"
      metadata = {
        contract_period_year: contract_period.year,
      }

      new(
        event_type:,
        author:,
        heading:,
        school_partnership:,
        delivery_partner:,
        school:,
        lead_provider:,
        happened_at: Time.zone.now,
        metadata:
      ).record_event!
    end

    def self.record_school_partnership_updated_event!(author:, school_partnership:, previous_delivery_partner:, modifications:)
      event_type = :school_partnership_updated
      school = school_partnership.school
      delivery_partner = school_partnership.delivery_partner
      lead_provider = school_partnership.lead_provider
      contract_period = school_partnership.contract_period
      heading = "#{school.name} changed partnership from #{previous_delivery_partner.name} to #{delivery_partner.name} (via #{lead_provider.name}) for #{contract_period.year}"
      metadata = {
        contract_period_year: contract_period.year,
      }

      new(
        event_type:,
        author:,
        heading:,
        school_partnership:,
        delivery_partner:,
        school:,
        lead_provider:,
        happened_at: Time.zone.now,
        metadata:,
        modifications:
      ).record_event!
    end

    # Statement Events

    def self.record_statement_authorised_for_payment_event!(author:, statement:, happened_at: Time.zone.now)
      event_type = :statement_authorised_for_payment

      active_lead_provider = statement.active_lead_provider
      lead_provider        = active_lead_provider.lead_provider
      heading              = "Statement authorised for payment"

      metadata = {
        contract_period_year: active_lead_provider.contract_period_year
      }

      new(
        event_type:,
        author:,
        heading:,
        statement:,
        active_lead_provider:,
        lead_provider:,
        happened_at:,
        metadata:
      ).record_event!
    end

    # Statement Adjustment Events

    def self.record_statement_adjustment_added_event!(author:, statement_adjustment:)
      event_type = :statement_adjustment_added
      heading = "Statement adjustment added: #{statement_adjustment.payment_type}"
      metadata = {
        payment_type: statement_adjustment.payment_type,
        amount: statement_adjustment.amount,
      }

      statement = statement_adjustment.statement
      active_lead_provider = statement.active_lead_provider
      lead_provider = active_lead_provider.lead_provider

      new(
        event_type:,
        author:,
        heading:,
        statement:,
        statement_adjustment:,
        active_lead_provider:,
        lead_provider:,
        happened_at: Time.zone.now,
        metadata:
      ).record_event!
    end

    def self.record_statement_adjustment_updated_event!(author:, statement_adjustment:)
      event_type = :statement_adjustment_updated
      heading = "Statement adjustment updated: #{statement_adjustment.payment_type}"
      metadata = {
        payment_type: statement_adjustment.payment_type,
        amount: statement_adjustment.amount,
      }

      statement = statement_adjustment.statement
      active_lead_provider = statement.active_lead_provider
      lead_provider = active_lead_provider.lead_provider

      new(
        event_type:,
        author:,
        heading:,
        statement:,
        statement_adjustment:,
        active_lead_provider:,
        lead_provider:,
        happened_at: Time.zone.now,
        metadata:
      ).record_event!
    end

    def self.record_statement_adjustment_deleted_event!(author:, statement_adjustment:)
      event_type = :statement_adjustment_deleted
      heading = "Statement adjustment deleted: #{statement_adjustment.payment_type}"
      metadata = {
        payment_type: statement_adjustment.payment_type,
        amount: statement_adjustment.amount,
      }

      statement = statement_adjustment.statement
      active_lead_provider = statement.active_lead_provider
      lead_provider = active_lead_provider.lead_provider

      new(
        event_type:,
        author:,
        heading:,
        statement:,
        active_lead_provider:,
        lead_provider:,
        happened_at: Time.zone.now,
        metadata:
      ).record_event!
    end

    # Lead Provider Delivery Partnership Events

    def self.record_lead_provider_delivery_partnership_added_event!(author:, delivery_partner:, lead_provider:, contract_period:, lead_provider_delivery_partnership:)
      event_type = :lead_provider_delivery_partnership_added
      heading = "#{lead_provider.name} partnered with #{delivery_partner.name} for #{contract_period.year}"

      new(
        event_type:,
        author:,
        heading:,
        delivery_partner:,
        lead_provider:,
        lead_provider_delivery_partnership:,
        happened_at: Time.zone.now
      ).record_event!
    end

    def self.record_lead_provider_delivery_partnership_removed_event!(author:, delivery_partner:, lead_provider:, contract_period:, lead_provider_delivery_partnership:)
      event_type = :lead_provider_delivery_partnership_removed
      heading = "#{lead_provider.name} partnership with #{delivery_partner.name} for #{contract_period.year} removed"

      new(
        event_type:,
        author:,
        heading:,
        delivery_partner:,
        lead_provider:,
        lead_provider_delivery_partnership:,
        happened_at: Time.zone.now
      ).record_event!
    end

    # Delivery Partner Events

    def self.record_delivery_partner_name_changed_event!(author:, delivery_partner:, from:, to:, happened_at: Time.zone.now)
      event_type    = :delivery_partner_name_changed
      heading       = "Delivery partner name changed"
      modifications = { "name" => [from, to] }

      new(
        event_type:,
        author:,
        delivery_partner:,
        heading:,
        happened_at:,
        modifications:
      ).record_event!
    end

    # Admin events

    def self.record_dfe_user_created_event!(author:, user:, modifications:, happened_at: Time.zone.now)
      event_type = :dfe_user_created
      heading = "User #{user.name} added"

      new(event_type:, author:, user:, heading:, modifications:, happened_at:).record_event!
    end

    def self.record_dfe_user_updated_event!(author:, user:, modifications:, happened_at: Time.zone.now)
      event_type = :dfe_user_updated
      heading = "User #{user.name} updated"

      new(event_type:, author:, user:, heading:, modifications:, happened_at:).record_event!
    end

  private

    def attributes
      { **event_attributes, **author_attributes, **relationship_attributes, **changelog_attributes }
    end

    def event_attributes
      {
        event_type:,
        heading:,
        body:,
        happened_at:,
        zendesk_ticket_id:,
      }.compact
    end

    # TODO: refactor to always use event_author_params
    def author_attributes
      case author
      when Sessions::User
        author.event_author_params
      when Events::SystemAuthor
        author.system_author_params
      when Events::LeadProviderAPIAuthor
        author.lead_provider_api_author_params
      when Events::AppropriateBodyBatchAuthor
        author.event_author_params
      else
        fail(InvalidAuthor, author.class)
      end
    end

    def relationship_attributes
      {
        school:,
        induction_period:,
        teacher:,
        appropriate_body:,
        induction_extension:,
        ect_at_school_period:,
        mentor_at_school_period:,
        training_period:,
        schedule:,
        mentorship_period:,
        school_partnership:,
        lead_provider:,
        delivery_partner:,
        active_lead_provider:,
        lead_provider_delivery_partnership:,
        statement:,
        statement_adjustment:,
        user:,
        pending_induction_submission_batch:,
      }.compact
    end

    def changelog_attributes
      { modifications:, metadata: }.compact
    end

    def check_relationship_attributes_are_persisted
      relationship_attributes.each { |name, object| fail(NotPersistedRecord, name) if object && !object.persisted? }
    end
  end
end
