class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |school, options|
      school_contrat_period_id(school, options)
    end
    field(:in_partnership) do |school, options|
      in_partnership?(school, options)
    end
    field(:induction_programme_choice) do |school, options|
      training_programme_for(school, options)
    end
    field(:expression_of_interest) do |school, options|
      expressions_of_interest?(school, options)
    end
    field :created_at
    field(:api_updated_at, name: :updated_at)

    class << self
      def school_contrat_period_id(school, options)
        if school.respond_to?(:transient_contract_period_id)
          school.transient_contract_period_id
        else
          options[:contract_period_id].to_s
        end
      end

      def training_programme_for(school, options)
        if school.respond_to?(:transient_lead_provider_contract_period)
          school.transient_lead_provider_contract_period[1]
        else
          school.training_programme_for(options[:contract_period_id].to_s)
        end
      end

      def in_partnership?(school, options)
        if school.respond_to?(:transient_lead_provider_contract_period)
          school.transient_lead_provider_contract_period[0]
        else
          school.school_partnerships.for_contract_period(options[:contract_period_id]).exists?
        end
      end

      def expressions_of_interest?(school, options)
        return school.transient_lead_provider_contract_period[2] if school.respond_to?(:transient_lead_provider_contract_period)

        school.ect_at_school_periods.with_expressions_of_interest_for_lead_provider_and_contract_period(options[:contract_period_id], options[:lead_provider_id]).exists? ||
          school.mentor_at_school_periods.with_expressions_of_interest_for_lead_provider_and_contract_period(options[:contract_period_id], options[:lead_provider_id]).exists?
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
