class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |school, _|
      school.transient_contract_period_id
    end
    field(:in_partnership) do |school, _|
      in_partnership?(school)
    end
    field(:induction_programme_choice) do |school, _|
      school.training_programme_for(school.transient_contract_period_id)
    end
    field(:expression_of_interest) do |school, _|
      expressions_of_interest?(school)
    end
    field :created_at
    field :updated_at

    class << self
      def in_partnership?(school)
        if school.respond_to?(:transient_in_partnership)
          school.transient_in_partnership
        else
          school.school_partnerships.for_contract_period(contract_period_id).exists?
        end
      end

      def expressions_of_interest?(school)
        if school.respond_to?(:transient_expression_of_interest_ects) &&
            school.respond_to?(:transient_expression_of_interest_mentors)
          return school.transient_expression_of_interest_ects ||
              school.transient_expression_of_interest_mentors
        end

        school.ect_at_school_periods.with_expressions_of_interest_for_lead_provider_and_contract_period(school.transient_contract_period_id, school.transient_lead_provider_id).exists? ||
          school.mentor_at_school_periods.with_expressions_of_interest_for_lead_provider_and_contract_period(school.transient_contract_period_id, school.transient_lead_provider_id).exists?
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
