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
                :school_partnership,
                :lead_provider,
                :delivery_partner,
                :active_lead_provider,
                :statement,
                :statement_adjustment,
                :user,
                :modifications,
                :metadata

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
      school_partnership: nil,
      lead_provider: nil,
      delivery_partner: nil,
      active_lead_provider: nil,
      statement: nil,
      statement_adjustment: nil,
      user: nil,
      modifications: nil,
      metadata: nil
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
      @school_partnership = school_partnership
      @lead_provider = lead_provider
      @delivery_partner = delivery_partner
      @active_lead_provider = active_lead_provider
      @statement = statement
      @statement_adjustment = statement_adjustment
      @user = user
      @modifications = DescribeModifications.new(modifications).describe
      @metadata = metadata || modifications
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
      heading = 'Induction period updated by admin'

      new(event_type:, modifications:, author:, appropriate_body:, induction_period:, teacher:, heading:, happened_at:).record_event!
    end

    def self.record_induction_period_deleted_event!(author:, modifications:, teacher:, appropriate_body:, body: nil, happened_at: Time.zone.now)
      event_type = :induction_period_deleted
      heading = 'Induction period deleted by admin'

      new(event_type:, modifications:, author:, appropriate_body:, teacher:, heading:, happened_at:, body:).record_event!
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
      heading = "Name changed from '#{old_name}' to '#{new_name}'"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_induction_status_changed_in_trs_event!(old_induction_status:, new_induction_status:, author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_trs_induction_status_updated
      heading = "Induction status changed from '#{old_induction_status}' to '#{new_induction_status}'"

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

    def self.record_induction_period_reopened_event!(author:, induction_period:, modifications:, teacher:, appropriate_body:, body: nil)
      event_type = :induction_period_reopened
      happened_at = Time.zone.now

      heading = 'Induction period reopened'

      new(event_type:, induction_period:, modifications:, author:, appropriate_body:, teacher:, heading:, happened_at:, body:).record_event!
    end

    # ECT and mentor events

    def self.record_teacher_registered_as_mentor_event!(author:, mentor_at_school_period:, teacher:, school:, happened_at: Time.zone.now)
      event_type = :teacher_registered_as_mentor
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was registered as a mentor at #{school.name}"

      new(event_type:, author:, heading:, mentor_at_school_period:, teacher:, school:, happened_at:).record_event!
    end

    def self.record_teacher_registered_as_ect_event!(author:, ect_at_school_period:, teacher:, school:, training_period:, happened_at: Time.zone.now)
      event_type = :teacher_registered_as_ect
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name} was registered as an ECT at #{school.name}"

      new(event_type:, author:, heading:, ect_at_school_period:, teacher:, school:, training_period:, happened_at:).record_event!
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

    # Bulk Upload Events

    def self.record_bulk_upload_started_event!(author:, batch:, csv_data:)
      event_type = :bulk_upload_started
      heading = "#{batch.appropriate_body.name} started a bulk #{batch.batch_type}"
      metadata = {
        batch_id: batch.id,
        batch_type: batch.batch_type,
        rows: batch.rows.count,
        **csv_data.metadata
      }

      new(event_type:, author:, appropriate_body: batch.appropriate_body, heading:, happened_at: Time.zone.now, metadata:).record_event!
    end

    def self.record_bulk_upload_completed_event!(author:, batch:)
      event_type = :bulk_upload_completed
      heading = "#{batch.appropriate_body.name} completed a bulk #{batch.batch_type}"
      metadata = {
        batch_id: batch.id,
        batch_type: batch.batch_type,
        batch_status: batch.batch_status,
        total: batch.pending_induction_submissions.count,
        skipped: batch.pending_induction_submissions.with_errors.count,
        passed: batch.pending_induction_submissions.pass.count,
        failed: batch.pending_induction_submissions.fail.count,
        released: batch.pending_induction_submissions.release.count,
      }

      new(event_type:, author:, appropriate_body: batch.appropriate_body, heading:, happened_at: Time.zone.now, metadata:).record_event!
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
      }.compact
    end

    def author_attributes
      case author
      when Sessions::User
        author.event_author_params
      when Events::SystemAuthor
        author.system_author_params
      when Events::AppropriateBodyBackgroundJobAuthor
        author.author_params
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
        mentorship_period:,
        school_partnership:,
        lead_provider:,
        delivery_partner:,
        active_lead_provider:,
        statement:,
        statement_adjustment:,
        user:,
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
