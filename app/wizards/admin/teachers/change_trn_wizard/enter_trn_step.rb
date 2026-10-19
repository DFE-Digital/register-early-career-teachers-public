module Admin
  module Teachers
    module ChangeTRNWizard
      class EnterTRNStep < Step
        attribute :trn, :string

        validates :trn,
                  teacher_reference_number: true,
                  presence: {
                    message: "Enter the teacher reference number (TRN)"
                  }

        def self.permitted_params = [:trn]

        def next_step = :confirm

        def save!
          clear_proposed_details
          return false unless valid?

          trs_teacher = ::TRS::APIClient.build.find_teacher(
            trn: formatted_trn
          )

          store.trn = formatted_trn
          store.trs_first_name = trs_teacher.trs_first_name
          store.trs_last_name = trs_teacher.trs_last_name

          true
        rescue ::TRS::Errors::TeacherNotFound
          errors.add(:trn, "No teacher was found with this TRN")
          false
        rescue ::TRS::Errors::TeacherDeactivated
          errors.add(:trn, "This TRN has been deactivated")
          false
        end

      private

        def clear_proposed_details
          store.trn = nil
          store.trs_first_name = nil
          store.trs_last_name = nil
        end

        def formatted_trn
          ::Schools::Validation::TeacherReferenceNumber
            .new(trn)
            .formatted_trn
        end

        def pre_populate_attributes
          self.trn = store.trn
        end
      end
    end
  end
end
