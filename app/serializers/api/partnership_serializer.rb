module API
  class PartnershipSerializer < Blueprinter::Base
    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:cohort) { |p, _| p.registration_period.year.to_s }
      field(:urn) { |p, _| p.school.urn.to_s }
      field(:school_id) { |p, _| p.school.id }
      field(:delivery_partner_id) { |p, _| p.delivery_partner.id }
      field(:delivery_partner_name) { |p, _| p.delivery_partner.name }

      field :created_at
      field :updated_at
    end

    identifier :id
    field(:type) { "partnership" }

    association :attributes, blueprint: AttributesSerializer do |partnership|
      partnership
    end
  end
end
