module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class EditStep < Step
        attribute :appropriate_body_id, :string
        attribute :appropriate_body_type, :string

        validates :appropriate_body_id,
                  presence: {
                    message: "Select the appropriate body which will be supporting the ECT's induction"
                  }

        def initialize(opts = {})
          super(**opts)

          set_national_appropriate_body_id
        end

        def self.permitted_params = %i[appropriate_body_id appropriate_body_type]

        def next_step = :check_answers

        def save!
          store.appropriate_body_id = appropriate_body_id if valid_step?
        end

        def appropriate_bodies_except_current
          AppropriateBodyPeriod
            .teaching_school_hub
            .active
            .where.not(id: current_appropriate_body_id)
            .select(:id, :name)
        end

      private

        def set_national_appropriate_body_id
          return unless ect_at_school_period.school.independent?
          return unless appropriate_body_type == "national"

          self.appropriate_body_id = AppropriateBodies::Search.istip.id.to_s
        end

        def pre_populate_attributes
          self.appropriate_body_id = store.appropriate_body_id
        end

        def current_appropriate_body_id
          ect_at_school_period.school_reported_appropriate_body_id
        end
      end
    end
  end
end
