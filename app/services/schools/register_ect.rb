module Schools
  class RegisterECT
    attr_reader :school_reported_appropriate_body,
                :corrected_name,
                :email,
                :lead_provider,
                :training_programme,
                :school,
                :started_on,
                :teacher,
                :trn,
                :trs_first_name,
                :trs_last_name,
                :working_pattern,
                :author,
                :ect_at_school_period

    def initialize(school_reported_appropriate_body:,
                   corrected_name:,
                   email:,
                   lead_provider:,
                   training_programme:,
                   school:,
                   started_on:,
                   trn:,
                   trs_first_name:,
                   trs_last_name:,
                   working_pattern:,
                   author:)
      @school_reported_appropriate_body = school_reported_appropriate_body
      @corrected_name = corrected_name
      @email = email
      @lead_provider = lead_provider
      @training_programme = training_programme
      @school = school
      @started_on = started_on
      @trn = trn
      @trs_first_name = trs_first_name
      @trs_last_name = trs_last_name
      @working_pattern = working_pattern
      @author = author
    end

    def register!
      not_registered_as_an_ect!

      ActiveRecord::Base.transaction do
        update_school_last_choices!
        create_teacher!
        @ect_at_school_period = start_at_school!
        create_training_period! if lead_provider.present?
        record_event!
      end

      @ect_at_school_period
    end

  private

    def already_registered_as_an_ect?
      ::Teacher.find_by_trn(trn)&.ect_at_school_periods&.exists?
    end

    def not_registered_as_an_ect!
      raise ActiveRecord::RecordInvalid if already_registered_as_an_ect?
    end

    def create_teacher!
      @teacher = ::Teacher.create_with(trs_first_name:, trs_last_name:, corrected_name:).find_or_create_by!(trn:)
    end

    def registration_period
      @registration_period ||= RegistrationPeriod.for_date(started_on)
    end

    def active_lead_provider
      @active_lead_provider ||= ActiveLeadProvider.find_by(
        lead_provider:,
        registration_period:
      ) || raise("Missing ActiveLeadProvider for #{lead_provider&.name} in #{registration_period&.year}")
    end

    def school_partnership
      provider = active_lead_provider
      return unless provider

      SchoolPartnership
        .joins(:lead_provider_delivery_partnership)
        .find_by(
          school:,
          lead_provider_delivery_partnerships: {
            active_lead_provider_id: provider.id
          }
        )
    end

    def expression_of_interest
      school_partnership ? nil : active_lead_provider
    end

    def create_training_period!
      ::TrainingPeriod.create!(
        ect_at_school_period:,
        started_on: ect_at_school_period.started_on,
        school_partnership:,
        expression_of_interest:
      )
    end

    def start_at_school!
      teacher.ect_at_school_periods.build(school_reported_appropriate_body:,
                                          email:,
                                          lead_provider:,
                                          training_programme:,
                                          school:,
                                          started_on:,
                                          working_pattern:) do |ect|
        ect.save!(context: :register_ect)
      end
    end

    def update_school_last_choices!
      school.update!(last_chosen_appropriate_body: school_reported_appropriate_body,
                     last_chosen_lead_provider: lead_provider,
                     last_chosen_training_programme: training_programme)
    end

    def record_event!
      Events::Record.record_teacher_registered_as_ect_event!(author:, ect_at_school_period:, teacher:, school:)
    end
  end
end
