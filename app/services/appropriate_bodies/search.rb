module AppropriateBodies
  class Search
    def initialize(query_string = nil)
      @scope = AppropriateBodyPeriod

      @query_string = query_string
    end

    def self.istip
      AppropriateBodyPeriod.national.joins(:national_body).find_by(national_bodies: { name: ::NationalBody::ISTIP }) ||
        raise(ActiveRecord::RecordNotFound, "ISTIP appropriate body period not found!")
    end

    def self.esp
      AppropriateBodyPeriod.national.joins(:national_body).find_by(national_bodies: { name: ::NationalBody::ESP }) ||
        raise(ActiveRecord::RecordNotFound, "ESP appropriate body period not found!")
    end

    def find_by_dfe_sign_in_organisation_id(dfe_sign_in_organisation_id)
      @scope.find_by(dfe_sign_in_organisation_id:)
    end

    # Only ABPs with a DSI UUID are currently surfaced meaning the majority are hidden.
    # Moving to body_type specific search so ABP names can be treated differently in the future
    # for teaching school hubs.
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
