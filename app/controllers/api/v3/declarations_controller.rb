module API
  module V3
    class DeclarationsController < APIController
      def index
        conditions = {
          contract_period_years: extract_conditions(contract_period_years, integers: true),
          teacher_api_ids: extract_conditions(teacher_api_ids, uuids: true),
          delivery_partner_api_ids: extract_conditions(delivery_partner_api_ids, uuids: true),
          updated_since:,
        }
        paginated_declarations = declarations_query(conditions:).declarations { paginate(it) }

        render json: to_json(paginated_declarations)
      end

      def show
        render json: to_json(declarations_query.declaration_by_api_id(api_id))
      end

      def create = head(:method_not_allowed)

      def void
        if declaration.payment_status_paid?
          service = API::Declarations::Clawback.new(**void_declaration_params)
          respond_with_service(service:, action: :clawback)
        else
          service = API::Declarations::Void.new(**void_declaration_params)
          respond_with_service(service:, action: :void)
        end
      end

    private

      def declarations_query(conditions: {})
        API::Declarations::Query.new(**(default_query_conditions.merge(conditions)).compact)
      end

      def default_query_conditions
        @default_query_conditions ||= {
          lead_provider_id: current_lead_provider.id,
        }
      end

      def serializer_options
        @serializer_options ||= {
          lead_provider_id: current_lead_provider.id
        }
      end

      def declarations_params
        params.permit(:api_id, filter: %i[cohort participant_id delivery_partner_id updated_since])
      end

      def void_declaration_params
        { lead_provider_id: current_lead_provider.id, declaration_api_id: declaration.api_id }
      end

      def declaration
        declarations_query.declaration_by_api_id(api_id)
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
        API::DeclarationSerializer.render(obj, root: "data", **serializer_options)
      end
    end
  end
end
