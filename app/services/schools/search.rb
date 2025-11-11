module Schools
  class Search
    def initialize(q)
      @q = q
    end

    def search
      query.merge(GIAS::School.ordered_by_name)
    end

  private

    def all_schools
      School.joins(:gias_school)
    end

    def query
      @q.blank? ? all_schools : all_schools.search(@q)
    end
  end
end
