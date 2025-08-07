module Teachers
  class Search
    attr_reader :scope

    def initialize(query_string: :ignore, appropriate_bodies: :ignore, ect_at_school: :ignore, mentor_at_school: :ignore, status: nil)
      @scope = Teacher.all

      where_ect_at(ect_at_school)
      where_mentor_at(mentor_at_school)
      where_appropriate_bodies_in(appropriate_bodies, status)
      matching(query_string)
    end

    def search
      scope.order(order)
    end

    delegate :count, to: :scope

  private

    def order
      case @sort_order
      when :mentorless_first_then_by_registration_date
        # mentorless teachers first, sorted by the registration date
        # at the school, latest first
        [
          Arel::Nodes::Case.new
                          .when(MentorshipPeriod.arel_table[:id].eq(nil)).then(0)
                          .else(1)
                          .asc,
          { ect_at_school_periods: { created_at: 'desc' } }
        ]
      else
        %i[trs_last_name trs_first_name id]
      end
    end

    def matching(query_string)
      return if query_string == :ignore
      return if query_string.nil?

      trns = query_string.scan(%r(\d{7}))

      (trns.any?) ? with_trns(trns) : where_query_matches(query_string)
    end

    def where_appropriate_bodies_in(appropriate_bodies, status)
      return if appropriate_bodies == :ignore

      ects_service = AppropriateBodies::ECTs.new(appropriate_bodies)
      @scope = ects_service.with_status(status)
    end

    def with_trns(trns)
      @scope.merge!(@scope.where(trn: trns))
    end

    def where_query_matches(query_string)
      return if query_string.blank?

      @scope.merge!(@scope.search(query_string))
    end

    def where_ect_at(school)
      return if school == :ignore

      @scope.merge!(
        @scope.includes(**ect_information)
              .where(ect_at_school_periods: { school: })
              .merge(ECTAtSchoolPeriod.ongoing_today_or_starting_tomorrow_or_after)
      )

      @sort_order = :mentorless_first_then_by_registration_date
    end

    def where_mentor_at(school)
      return if school == :ignore

      @scope = @scope
        .joins(:mentor_at_school_periods)
        .where(mentor_at_school_periods: { school_id: school.id })
        .distinct
        .includes(:mentor_at_school_periods)
    end

    def ect_information
      {
        current_ect_at_school_period: [
          :school,
          :school_reported_appropriate_body,
          {
            mentorship_periods: {
              mentor: :teacher,
            },
            current_training_period: {
              school_partnership: {
                lead_provider_delivery_partnership: [
                  :delivery_partner,
                  { active_lead_provider: %i[lead_provider contract_period] }
                ]
              }
            }
          }
        ]
      }
    end
  end
end
