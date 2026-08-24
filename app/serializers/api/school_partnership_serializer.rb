class API::SchoolPartnershipSerializer < Blueprinter::Base
  def self.dependencies
    [
      :delivery_partner,
      :framework_agreement,
      :ongoing_training_periods,
      {
        school: :gias_school
      }
    ]
  end

  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :cohort do |partnership, _options|
      partnership.framework_agreement.contract_period_year.to_s
    end

    field :urn do |partnership, _options|
      partnership.school.urn.to_s
    end

    field :school_id do |partnership, _options|
      partnership.school.api_id
    end

    field :delivery_partner_id do |partnership, _options|
      partnership.delivery_partner.api_id
    end

    field :delivery_partner_name do |partnership, _options|
      partnership.delivery_partner.name
    end

    field :induction_tutor_name do |partnership, _options|
      partnership.school.induction_tutor_name
    end

    field :induction_tutor_email do |partnership, _options|
      Schools::InductionTutorEmail.new(school: partnership.school).email_or_gias_contact
    end

    # Changes to this field will be reflected in the `updated_at` via the nightly
    # TouchSchoolPartnershipForParticipantsCurrentlyTrainingJob.
    field(:participants_currently_training) do |partnership, _options|
      partnership.ongoing_training_periods.size
    end

    field :created_at
    field(:api_updated_at, name: :updated_at)
  end

  identifier :api_id, name: :id
  field(:type) { "partnership" }

  association :attributes, blueprint: AttributesSerializer do |partnership|
    partnership
  end
end
