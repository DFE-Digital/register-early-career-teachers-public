module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class EditStep < Step
        attribute :appropriate_body_id, :string

        validates :appropriate_body_id,
                  presence: { message: "Select the appropriate body which will be supporting the ECT's induction" }

        validate :appropriate_body_id_must_change, if: -> { appropriate_body_id.present? }

        def self.permitted_params = [:appropriate_body_id]

        def next_step = :check_answers

        def save!
          store.appropriate_body_id = appropriate_body_id if valid_step?
        end

      private

        def pre_populate_attributes
          self.appropriate_body_id = store.appropriate_body_id
        end

        def appropriate_body_id_must_change
          return unless appropriate_body_id == ect_at_school_period.school_reported_appropriate_body_id.to_s

          errors.add(:appropriate_body_id, "You must select a different appropriate body")
        end
      end
    end
  end
end
