module Teachers
  class Search
    attr_reader :scope

    def initialize(query_string: :ignore, appropriate_bodies: :ignore, ect_at_school: :ignore)
      @scope = Teacher.all

      where_ect_at(ect_at_school)
      where_appropriate_bodies_in(appropriate_bodies)
      matching(query_string)
    end

    def search
      scope.order(:trs_last_name, :trs_first_name, :id)
    end

  private

    def matching(query_string)
      return if query_string == :ignore
      return if query_string.nil?

      trns = query_string.scan(%r(\d{7}))

      (trns.any?) ? with_trns(trns) : where_query_matches(query_string)
    end

    def where_appropriate_bodies_in(appropriate_bodies)
      return if appropriate_bodies == :ignore

      @scope = AppropriateBodies::ECTs.new(appropriate_bodies).current_or_completed_while_at_appropriate_body
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
        @scope.eager_load(ect_at_school_periods: [:school, { mentorship_periods: { mentor: :teacher } }])
              .where(ect_at_school_periods: { school: })
              .merge(ECTAtSchoolPeriod.ongoing)
      )
    end
  end
end
