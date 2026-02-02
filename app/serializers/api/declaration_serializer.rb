class API::DeclarationSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:participant_id) { |declaration| declaration.training_period.teacher.api_id }
    field(:declaration_type)
    field(:declaration_date)

    field(:course_identifier) do |declaration|
      if declaration.training_period.for_ect?
        "ecf-induction"
      elsif declaration.training_period.for_mentor?
        "ecf-mentor"
      end
    end

    field(:state) do |declaration|
      status = declaration.overall_status
      # This is for ecf1 consistency as "submitted" has been renamed to "no_payment" on rect
      status == "no_payment" ? "submitted" : status
    end

    field(:updated_at)
    field(:created_at)
    field(:delivery_partner_id) { |declaration| declaration.training_period.delivery_partner.api_id }
    field(:statement_id) { |declaration| declaration.payment_statement&.api_id }
    field(:clawback_statement_id) { |declaration| declaration.clawback_statement&.api_id }
    # This will be removed at a later date, retaining for now for ECF parity and so
    # we don't have to communicate another change to LPs just yet.
    field(:ineligible_for_funding_reason) { nil }
    field(:mentor_id) { |declaration| declaration.mentorship_period&.mentor&.teacher&.api_id }
    field(:uplift_paid?, name: :uplift_paid)
    field(:evidence_type, name: :evidence_held)
    field(:lead_provider_name) { |declaration| declaration.training_period.lead_provider.name }
  end

  identifier :api_id, name: :id
  field(:type) { "participant-declaration" }

  association :attributes, blueprint: AttributesSerializer do |declaration|
    declaration
  end
end
