module ECTAtSchoolPeriods
  class TextSearch
    def initialize(initial_cohort, query_string:)
      @initial_cohort = initial_cohort
      @query_string = query_string
    end

    def search
      if @query_string.blank?
        @initial_cohort
      elsif trns.any?
        @initial_cohort.joins(:teacher).where(teachers: { trn: trns })
      else
        @initial_cohort.joins(:teacher).merge(Teacher.search(@query_string))
      end
    end

  private

    def trns
      @trns ||= @query_string.scan(/\d{7}/)
    end
  end
end
