module API
  module V3
    class DeclarationsController < ActionController::API
      include API::TokenAuthenticatable
      include API::Paginatable
      include API::ErrorRescuable
      include API::DateFilterable
      include API::ContractPeriodFilterable
      include API::FilterValidatable
      include API::Orderable
      include API::ConditionExtractable
      include API::Analyticable
      include API::ServiceRespondable
      include API::TeacherType

      def index
        filters = {
          contract_period_years: extract_conditions(contract_period_years, type: :integer),
          teacher_api_ids: extract_conditions(teacher_api_ids, type: :uuid),
          delivery_partner_api_ids: extract_conditions(delivery_partner_api_ids, type: :uuid),
          updated_since:,
        }
        paginated_declarations = paginate(lead_provider_declarations_query(filters:).declarations)

        render json: to_json(paginated_declarations)
      end

      def show
        render json: to_json(lead_provider_declarations_query.declaration_by_api_id(api_id))
      end

      def create
        service = API::Declarations::Create.new({
          **lead_provider_filter,
          declaration_date: create_declaration_params[:declaration_date],
          declaration_type: create_declaration_params[:declaration_type],
          evidence_type: create_declaration_params[:evidence_held],
          teacher_api_id: create_declaration_params[:participant_id],
          teacher_type:
        })

        respond_with_service(service:, action: :create)
      end

      def void
        service_args = { **lead_provider_filter, declaration_api_id: declaration.api_id }

        if declaration.payment_status_paid?
          service = API::Declarations::Clawback.new(**service_args)
          respond_with_service(service:, action: :clawback)
        else
          service = API::Declarations::Void.new(**service_args)
          respond_with_service(service:, action: :void)
        end
      end

    private

      def create_declaration_params
        params.require(:data).expect({ attributes: %i[participant_id declaration_type declaration_date course_identifier evidence_held] })
      end

      def lead_provider_declarations_query(filters: {})
        declaration_filters = lead_provider_filter.merge(filters).compact
        included_associations = { included_associations: serializer.dependencies }

        API::Declarations::Query.new(**declaration_filters.merge(included_associations))
      end

      def lead_provider_filter
        { lead_provider_id: current_lead_provider.id }
      end

      def declarations_params
        params.permit(:api_id, filter: %i[cohort participant_id delivery_partner_id updated_since])
      end

      def declaration
        # We don't use the declarations query here as that will also return previous
        # declarations for other lead providers and we only want to let the lead
        # provider void on their own declarations.
        current_lead_provider.declarations.find_by!(api_id:)
      end

      def api_id
        declarations_params[:api_id]
      end

      def teacher_api_ids
        declarations_params.dig(:filter, :participant_id)
      end

      def delivery_partner_api_ids
        declarations_params.dig(:filter, :delivery_partner_id)
      end

      def to_json(obj)
        serializer.render(obj, root: "data", **lead_provider_filter)
      end

      def serializer
        API::DeclarationSerializer
      end
    end
  end
end
