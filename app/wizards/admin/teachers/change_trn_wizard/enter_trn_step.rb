module Admin
  module Teachers
    module ChangeTRNWizard
      class EnterTRNStep < Step
        attribute :trn, :string

        delegate :merge_proposed?, to: :wizard

        validates :trn,
                  teacher_reference_number: true,
                  presence: {
                    message: "Enter the teacher reference number (TRN)"
                  }
        validate :trn_must_be_different

        def self.permitted_params = [:trn]

        def next_step
          merge_proposed? ? :merge_preview : :confirm
        end

        def save!
          clear_proposed_details
          return false unless valid?

          trs_teacher = ::TRS::APIClient.build.find_teacher(
            trn: formatted_trn
          )

          store.trn = formatted_trn
          store.trs_first_name = trs_teacher.trs_first_name
          store.trs_last_name = trs_teacher.trs_last_name
          store.destination_teacher_id = Teacher
            .where.not(id: wizard.teacher_id)
            .find_by(trn: formatted_trn)
            &.id

          true
        rescue ::TRS::Errors::TeacherNotFound
          errors.add(:trn, "No teacher was found with this TRN")
          false
        rescue ::TRS::Errors::TeacherDeactivated
          errors.add(:trn, "This TRN has been deactivated")
          false
        end

      private

        def trn_must_be_different
          return if errors[:trn].any?
          return unless formatted_trn == wizard.teacher.trn

          errors.add(:trn, "Enter a different teacher reference number (TRN)")
        end

        def clear_proposed_details
          store.trn = nil
          store.trs_first_name = nil
          store.trs_last_name = nil
          store.destination_teacher_id = nil
          store.merge_previewed = nil
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
