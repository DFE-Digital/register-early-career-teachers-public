class API::DeclarationSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:participant_id) { |declaration| declaration.training_period.trainee.teacher.ecf_user_id }
    field(:declaration_type)
    # field(:course_identifier)
    # field(:declaration_date)
    # field(:state) { |declaration| declaration.state.dasherize }
    # field(:has_passed) do |declaration|
    #   declaration
    #     .participant_outcomes
    #     .max_by(&:created_at)
    #     &.has_passed?
    # end

    # field(:statement_id) { |declaration| declaration.billable_statement&.ecf_id }
    # field(:clawback_statement_id) { |declaration| declaration.refundable_statement&.ecf_id }
    field(:uplift_paid?, name: :uplift_paid)
    # field(:lead_provider_name)
    # field(:ineligible_for_funding_reason)
    field(:created_at)

    field(:updated_at)
  end

  # identifier :ecf_id, name: :id
  field(:type) { "participant-declaration" }

  association :attributes, blueprint: AttributesSerializer do |declaration|
    declaration
  end
end
