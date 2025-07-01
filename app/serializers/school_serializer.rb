class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |_school, options|
      options[:registration_period_id]&.to_s
    end
    field(:in_partnership) do |school, options|
      in_partnership?(school, options)
    end
    field(:induction_programme_choice) do |school, options|
      Schools::TrainingProgramme.new(school:, registration_period_id: options[:registration_period_id]).training_programme
    end
    field :created_at
    field(:updated_at) do |school, options|
      updated_at(school, options)
    end

    class << self
      def in_partnership?(school, options)
        return false if options[:registration_period_id].blank?

        school.school_partnerships.for_registration_period(options[:registration_period_id]).exists?
      end

      def updated_at(school, options)
        (
          (school.school_partnerships.for_registration_period(options[:registration_period_id]) || []).map(&:updated_at) +
          [school.updated_at]
        ).compact.max
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
