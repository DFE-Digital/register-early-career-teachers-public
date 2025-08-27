module Schools
  class Query
    include Queries::ConditionFormats
    include Queries::FilterIgnorable
    include Queries::Orderable

    attr_reader :scope, :sort

    def initialize(lead_provider_id: :ignore, urn: :ignore, updated_since: :ignore, contract_period_year: :ignore, sort: nil, ongoing_training_periods_count: false)
      @scope = default_scope(contract_period_year)
        .or(schools_with_existing_partnerships(contract_period_year))
        .includes(:contract_period_metadata, :lead_provider_contract_period_metadata)

      include_ongoing_training_periods_count(lead_provider_id) if ongoing_training_periods_count

      where_metadata_belongs_to_lead_provider(lead_provider_id)
      where_metadata_belongs_to_contract_period(contract_period_year)
      where_urn_is(urn)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    def schools
      scope
    end

    def school_by_api_id(api_id)
      return scope.find_by!(gias_school: { api_id: }) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school_by_id(id)
      return scope.find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

  private

    def where_metadata_belongs_to_lead_provider(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope
        .references(:metadata_schools_lead_providers_contract_periods)
        .where('metadata_schools_lead_providers_contract_periods.lead_provider_id' => [lead_provider_id, nil])
    end

    def where_metadata_belongs_to_contract_period(contract_period_year)
      return if ignore?(filter: contract_period_year)

      @scope = scope
        .references(:metadata_schools_contract_periods, :metadata_schools_lead_providers_contract_periods)
        .where('metadata_schools_contract_periods.contract_period_year' => [contract_period_year, nil])
        .where('metadata_schools_lead_providers_contract_periods.contract_period_year' => [contract_period_year, nil])
    end

    def schools_with_existing_partnerships(contract_period_year)
      School.where(id: School.select("schools.id")
        .joins(school_partnerships: { lead_provider_delivery_partnership: { active_lead_provider: :contract_period } })
        .where(contract_periods: { year: contract_period_year }))
    end

    def where_urn_is(urn)
      return if ignore?(filter: urn)

      scope.merge!(School.where(urn:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(School.where(updated_at: updated_since..))
    end

    def default_scope(contract_period_year)
      return School.none if ignore?(filter: contract_period_year) || ContractPeriod.find_by(year: contract_period_year).blank?

      School
        .eligible
        .not_cip_only
        .eager_load(:gias_school)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort_order(sort:, model: School, default: { created_at: :asc }))
    end

    def transient_ongoing_training_periods_subquery(lead_provider_id)
      <<~SQL.squish
        (
          SELECT COUNT(*)
          FROM training_periods

          INNER JOIN school_partnerships
          ON school_partnerships.id = training_periods.school_partnership_id

          INNER JOIN lead_provider_delivery_partnerships
          ON lead_provider_delivery_partnerships.id = school_partnerships.lead_provider_delivery_partnership_id

          INNER JOIN active_lead_providers
          ON active_lead_providers.id = lead_provider_delivery_partnerships.active_lead_provider_id

          INNER JOIN lead_providers
          ON lead_providers.id = active_lead_providers.lead_provider_id

          WHERE school_partnerships.school_id = schools.id
          AND lead_providers.id = #{ActiveRecord::Base.connection.quote(lead_provider_id)}
          AND training_periods.range @> CURRENT_DATE
        ) AS transient_ongoing_training_periods_count
      SQL
    end

    def include_ongoing_training_periods_count(lead_provider_id)
      @scope = @scope.select("schools.*", transient_ongoing_training_periods_subquery(lead_provider_id))
    end
  end
end
