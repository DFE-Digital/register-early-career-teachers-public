module Schools
  module RegisterECTWizard
    class IndependentSchoolAppropriateBodyStep < AppropriateBodyStep
      def self.permitted_params = %i[appropriate_body_id appropriate_body_type]

    private

      def initialize(opts = {})
        if opts[:appropriate_body_type] == 'national'
          @appropriate_body = AppropriateBody.istip
          opts[:appropriate_body_id] = @appropriate_body.id.to_s
        end

        super(**opts.except(:appropriate_body_type))
      end

      def persist = ect.update(appropriate_body_id:)

      def pre_populate_attributes
        self.appropriate_body_id = ect.appropriate_body_id
      end
    end
  end
end
