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
                :provider_partnership,
                :lead_provider,
                :delivery_partner,
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
      provider_partnership: nil,
      lead_provider: nil,
      delivery_partner: nil,
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
      @provider_partnership = provider_partnership
      @lead_provider = lead_provider
      @delivery_partner = delivery_partner
      @user = user
      @modifications = DescribeModifications.new(modifications).describe
      @metadata = metadata || modifications
    end

    def record_event!
      check_relationship_attributes_are_persisted
      # FIXME: This job is causing serialization errors when launched within a failing transaction block.
      # We have not yet identified the root cause of this issue therefore we're going to run the job inline for now.
      RecordEventJob.perform_later(**attributes)
    end

    # Induction period events

    def self.record_induction_period_opened_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :induction_period_opened
      heading = "#{Teachers::Name.new(teacher).full_name} was claimed by #{appropriate_body.name}"
      happened_at = induction_period.started_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    # Appropriate body events

    def self.record_appropriate_body_releases_teacher_event!(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :appropriate_body_releases_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} was released by #{appropriate_body.name}"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_appropriate_body_passes_teacher_event(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :appropriate_body_passes_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} passed induction"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_appropriate_body_fails_teacher_event(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :appropriate_body_fails_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} failed induction"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end
    # Teacher events

    def self.teacher_name_changed_in_trs!(old_name:, new_name:, author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_name_updated_by_trs
      heading = "Name changed from '#{old_name}' to '#{new_name}'"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_induction_status_changed_in_trs!(old_induction_status:, new_induction_status:, author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_induction_status_updated_by_trs
      heading = "Induction status changed from '#{old_induction_status}' to '#{new_induction_status}'"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_imported_from_trs!(author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_imported_from_trs
      heading = "Imported from TRS"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

    def self.teacher_attributes_updated_from_trs!(author:, teacher:, modifications:, happened_at: Time.zone.now)
      event_type = :teacher_attributes_updated_from_trs
      heading = "TRS attributes updated"

      new(event_type:, author:, modifications:, teacher:, heading:, happened_at:).record_event!
    end

    # Admin events

    def self.record_admin_updates_induction_period!(author:, modifications:, induction_period:, teacher:, appropriate_body:, happened_at: Time.zone.now)
      event_type = :admin_updates_induction_period

      heading = 'Induction period updated by admin'

      new(event_type:, modifications:, author:, appropriate_body:, induction_period:, teacher:, heading:, happened_at:).record_event!
    end

    def self.record_admin_creates_induction_period!(author:, modifications:, induction_period:, teacher:, appropriate_body:, happened_at: Time.zone.now)
      event_type = :admin_creates_induction_period

      heading = 'Induction period created by admin'

      new(event_type:, modifications:, author:, appropriate_body:, induction_period:, teacher:, heading:, happened_at:).record_event!
    end

    def self.record_admin_passes_teacher_event(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :admin_passes_teacher_induction
      heading = "#{Teachers::Name.new(teacher).full_name} passed induction (admin)"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_admin_fails_teacher_event(author:, appropriate_body:, induction_period:, teacher:)
      fail(NoInductionPeriod) unless induction_period

      event_type = :admin_fails_teacher_induction
      heading = "#{Teachers::Name.new(teacher).full_name} failed induction (admin)"
      happened_at = induction_period.finished_on

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_admin_reverts_teacher_claim_event!(author:, appropriate_body:, teacher:)
      event_type = :admin_reverts_teacher_claim
      heading = "#{Teachers::Name.new(teacher).full_name} was unclaimed by #{author.full_name}"
      happened_at = Time.zone.now
      body = "Induction status was reset on TRS"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:, body:).record_event!
    end

    def self.record_admin_deletes_induction_period!(author:, modifications:, teacher:, appropriate_body:, body: nil)
      event_type = :admin_deletes_induction_period
      happened_at = Time.zone.now

      heading = 'Induction period deleted by admin'

      new(event_type:, modifications:, author:, appropriate_body:, teacher:, heading:, happened_at:, body:).record_event!
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
        provider_partnership:,
        lead_provider:,
        delivery_partner:,
        user:
      }.compact
    end

    def changelog_attributes
      { modifications:, metadata: }.compact
    end

    def check_relationship_attributes_are_persisted
      relationship_attributes.each { |name, object| fail(NotPersistedRecord, name) unless object.persisted? }
    end
  end
end
