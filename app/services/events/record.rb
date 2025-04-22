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

    # Induction Extension Events

    def self.record_appropriate_body_adds_induction_extension_event!(author:, appropriate_body:, teacher:, induction_extension:, modifications:, happened_at: Time.zone.now)
      event_type = :appropriate_body_adds_induction_extension
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction extended by #{induction_extension.number_of_terms} terms"

      new(event_type:, author:, appropriate_body:, teacher:, induction_extension:, modifications:, heading:, happened_at:).record_event!
    end

    def self.record_appropriate_body_updates_induction_extension_event!(author:, appropriate_body:, teacher:, induction_extension:, modifications:, happened_at: Time.zone.now)
      event_type = :appropriate_body_updates_induction_extension
      teacher_name = Teachers::Name.new(teacher).full_name
      heading = "#{teacher_name}'s induction extended by #{induction_extension.number_of_terms} terms"

      new(event_type:, author:, appropriate_body:, teacher:, induction_extension:, modifications:, heading:, happened_at:).record_event!
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
        school_partnership:,
        lead_provider:,
        delivery_partner:,
        user:,
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
