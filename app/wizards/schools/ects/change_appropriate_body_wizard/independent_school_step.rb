module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class IndependentSchoolStep < EditStep
        def self.permitted_params =
          %i[appropriate_body_id appropriate_body_type]

      private

        def initialize(opts = {})
          if opts[:appropriate_body_type] == "national"
            opts[:appropriate_body_id] =
              AppropriateBodies::Search.istip.id.to_s
          end

          super(**opts.except(:appropriate_body_type))
        end
      end
    end
  end
end
