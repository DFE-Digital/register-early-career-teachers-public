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
      scope.reorder(order)
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
          {ect_at_school_periods: {created_at: "desc"}}
        ]
      else
        %i[trs_last_name trs_first_name id]
      end
    end

    def matching(query_string)
      return if query_string == :ignore
      return if query_string.nil?

      trns = query_string.scan(%r(\d{7}))

      trns.any? ? with_trns(trns) : where_query_matches(query_string)
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
        @scope
          .eager_load(current_or_next_ect_at_school_period: :mentorship_periods)
          .where(ect_at_school_periods: {school:})
      )

      @sort_order = :mentorless_first_then_by_registration_date
    end

    def where_mentor_at(school)
      return if school == :ignore

      @scope = @scope
        .joins(:mentor_at_school_periods)
        .where(mentor_at_school_periods: {school_id: school.id})
        .distinct
        .includes(:mentor_at_school_periods)
    end
  end
end
