module AppropriateBodies
  class Search
    def initialize(query_string = nil)
      @scope = AppropriateBody

      @query_string = query_string
    end

    def search
      query = if @query_string.blank?
                @scope.all
              else
                @scope.where("name ILIKE ?", "%#{@query_string}%")
              end

      query.order(name: 'asc')
    end

    def find_by_dfe_sign_in_organisation_id(dfe_sign_in_organisation_id)
      @scope.find_by(dfe_sign_in_organisation_id:)
    end
  end
end
