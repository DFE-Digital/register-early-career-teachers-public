class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |school, options|
      school_contract_period_year(school, options)
    end
    field(:in_partnership) do |school, options|
      in_partnership?(school, options)
    end
    field(:induction_programme_choice) do |school, options|
      school.training_programme_for(school_contract_period_year(school, options))
    end
    field(:expression_of_interest) do |school, options|
      expressions_of_interest?(school, options)
    end
    field :created_at
    field(:api_updated_at, name: :updated_at)

    class << self
      def school_contract_period_year(school, options)
        if school.respond_to?(:transient_contract_period_year)
          school.transient_contract_period_year
        else
          options[:contract_period_year].to_s
        end
      end

      def in_partnership?(school, options)
        if school.respond_to?(:transient_in_partnership)
          school.transient_in_partnership
        else
          school.school_partnerships.for_contract_period(options[:contract_period_year]).exists?
        end
      end

      def expressions_of_interest?(school, options)
        if school.respond_to?(:transient_expression_of_interest_ects) &&
            school.respond_to?(:transient_expression_of_interest_mentors)
          return school.transient_expression_of_interest_ects ||
              school.transient_expression_of_interest_mentors
        end

        school.expression_of_interest_for?(options[:lead_provider_id], options[:contract_period_year])
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
