module AppropriateBodies
  class Search
    def initialize(query_string = nil)
      @scope = AppropriateBodyPeriod

      @query_string = query_string
    end

    def self.istip
      new(::AppropriateBody::ISTIP).search.first ||
        raise(ActiveRecord::RecordNotFound, "ISTIP appropriate body period not found!")
    end

    def self.esp
      new(::AppropriateBody::ESP).search.first ||
        raise(ActiveRecord::RecordNotFound, "ESP appropriate body period not found!")
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

      query.order(name: "asc")
    end
  end
end
