module AppropriateBodies
  class Search
    ISTIP = 'Independent Schools Teacher Induction Panel (ISTIP)'.freeze

    def initialize(query_string = nil)
      @scope = AppropriateBody

      @query_string = query_string
    end

    def self.istip
      new(ISTIP).search.first || raise(ActiveRecord::RecordNotFound, "ISTIP appropriate body not found!")
    end

    def find_by_dfe_sign_in_organisation_id(dfe_sign_in_organisation_id)
      @scope.find_by(dfe_sign_in_organisation_id:)
    end

    def search
      query = if @query_string.blank?
                @scope.all
              else
                @scope.where("name ILIKE ?", "%#{@query_string}%")
              end

      query.order(name: 'asc')
    end
  end
end
