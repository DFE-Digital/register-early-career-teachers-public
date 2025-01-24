module Events
  class InvalidAuthor < StandardError; end

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
                :user

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
      user: nil
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
    end

    def record_event!
      RecordEventJob.perform_later(**attributes)
    end

    # Appropriate body events

    def self.record_appropriate_body_claims_teacher_event!(author:, appropriate_body:, induction_period:, teacher:, happened_at: Time.zone.now)
      event_type = :appropriate_body_claims_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} was claimed by #{appropriate_body.name}"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_appropriate_body_releases_teacher_event!(author:, appropriate_body:, induction_period:, teacher:, happened_at: Time.zone.now)
      event_type = :appropriate_body_releases_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} was released by #{appropriate_body.name}"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_appropriate_body_passes_teacher_event(author:, appropriate_body:, induction_period:, teacher:, happened_at: Time.zone.now)
      event_type = :appropriate_body_passes_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} passed induction"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    def self.record_appropriate_body_fails_teacher_event(author:, appropriate_body:, induction_period:, teacher:, happened_at: Time.zone.now)
      event_type = :appropriate_body_fails_teacher
      heading = "#{Teachers::Name.new(teacher).full_name} failed induction"

      new(event_type:, author:, appropriate_body:, teacher:, induction_period:, heading:, happened_at:).record_event!
    end

    # Teacher events

    def self.teacher_name_changed_in_trs!(old_name:, new_name:, author:, teacher:, appropriate_body: nil, happened_at: Time.zone.now)
      event_type = :teacher_name_updated_by_trs
      heading = "Name changed from #{old_name} to #{new_name}"

      new(event_type:, author:, appropriate_body:, teacher:, heading:, happened_at:).record_event!
    end

  private

    def attributes
      {
        **author_event_params,
        event_type:,
        heading:,
        body:,
        happened_at:,
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

    def author_event_params
      case author
      when Sessions::User
        author.event_author_params
      when Events::SystemAuthor
        author.system_author_params
      else
        fail(InvalidAuthor, author.class)
      end
    end
  end
end
