module API
  module V3
    class PartnershipsController < APIController
      def index
        query_arguments = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          updated_since:,
          delivery_partner_api_ids: extract_conditions(delivery_partner_api_ids),
          sort:
        }
        paginated_school_partnerships = paginate(partnerships_query(query_arguments:).school_partnerships)

        render json: to_json(paginated_school_partnerships)
      end

      def show
        render json: to_json(partnerships_query.school_partnership_by_api_id(api_id))
      end

      def create
        service = API::SchoolPartnerships::Create.new({
          lead_provider_id: current_lead_provider.id,
          contract_period_year: create_partnership_params[:cohort],
          school_api_id: create_partnership_params[:school_id],
          delivery_partner_api_id: create_partnership_params[:delivery_partner_id],
        })

        respond_with_service(service:, action: :create)
      end

      def update
        school_partnership = partnerships_query.school_partnership_by_api_id(api_id)

        service = API::SchoolPartnerships::Update.new({
          school_partnership_id: school_partnership.id,
          delivery_partner_api_id: update_partnership_params[:delivery_partner_id],
        })

        respond_with_service(service:, action: :update)
      end

    private

      def create_partnership_params
        params.require(:data).expect({ attributes: %i[cohort school_id delivery_partner_id] })
      end

      def update_partnership_params
        params.require(:data).expect({ attributes: %i[delivery_partner_id] })
      end

      def partnerships_query(query_arguments: {})
        API::SchoolPartnerships::Query.new(**(base_query_arguments.merge(query_arguments)).compact)
      end

      def base_query_arguments
        {
          lead_provider_id: current_lead_provider.id,
          included_associations: serializer.dependencies
        }
      end

      def partnerships_params
        params.permit(:api_id, :sort, filter: %i[delivery_partner_id])
      end

      def api_id
        partnerships_params[:api_id]
      end

      def sort
        sort_order(sort: partnerships_params[:sort], model: SchoolPartnership, default: { created_at: :asc })
      end

      def delivery_partner_api_ids
        partnerships_params.dig(:filter, :delivery_partner_id)
      end

      def to_json(obj)
        serializer.render(obj, root: "data")
      end

      def serializer
        API::SchoolPartnershipSerializer
      end
    end
  end
end
