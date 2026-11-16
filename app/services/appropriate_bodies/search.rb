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

    def find_by_dfe_sign_in_organisation_id(dfe_sign_in_organisation_id)
      @scope.find_by(dfe_sign_in_organisation_id:)
    end

    def search
      query = @query_string.present? ? @scope.matching_display_name(@query_string) : @scope.with_display_names

      query.strict_loading.ordered_by_display_name
    end
  end
end
