module Events
  class NotASessionsUser < StandardError; end

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
      fail(NotASessionsUser, author.class) unless author.is_a?(Sessions::User)

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
      # FIXME: this should probably end up in a job
      #        we don't want to block the app from working
      #        if some validation fails or something goes
      #        wrong while creating the event, but we
      #        do care enough to investigate and the problem
      #        without losing data
      Event.create!(**attributes)
    end

  private

    def attributes
      {
        **author.event_author_params,
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
      }
    end
  end
end
