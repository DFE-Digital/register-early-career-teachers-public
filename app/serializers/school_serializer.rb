class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |_school, options|
      options[:contract_period_id]&.to_s
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
    field :updated_at

    class << self
      def in_partnership?(school, options)
        return false if options[:contract_period_id].blank?
        return school.transient_in_partnership if school.respond_to?(:transient_in_partnership)

        school.school_partnerships.for_contract_period(options[:contract_period_id]).exists?
      end

      def training_programme_for(school, options)
        Schools::TrainingProgramme.new(school:, contract_period_id: options[:contract_period_id]).training_programme
      end

      def expressions_of_interest?(school, options)
        return school.transient_expression_of_interest if school.respond_to?(:transient_expression_of_interest)

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
