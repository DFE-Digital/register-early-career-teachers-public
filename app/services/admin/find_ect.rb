module Admin
  class FindECT
    attr_reader :pending_induction_submission

    def initialize(pending_induction_submission:)
      @pending_induction_submission = pending_induction_submission
    end

    def import_from_trs!
      return unless pending_induction_submission.valid?(:find_ect)

      pending_induction_submission.assign_attributes(**trs_teacher.present.except(:trs_national_insurance_number))

      check_if_teacher_already_exists!
      check_trs_induction_status!

      trs_teacher.check_eligibility!

      pending_induction_submission.save(context: :find_ect)
    end

  private

    def trs_teacher
      @trs_teacher ||= api_client.find_teacher(trn: pending_induction_submission.trn, date_of_birth: pending_induction_submission.date_of_birth)
    end

    def api_client
      @api_client ||= TRS::APIClient.build
    end

    def check_if_teacher_already_exists!
      existing_teacher = Teacher.find_by(trn: pending_induction_submission.trn)

      return unless existing_teacher

      raise ::AppropriateBodies::Errors::TeacherAlreadyExists, ::Teachers::Name.new(existing_teacher).full_name
    end

    def check_trs_induction_status!
      invalid_statuses = %w[Passed Failed Exempt]

      return unless invalid_statuses.include?(pending_induction_submission.trs_induction_status)

      raise ::TRS::Errors::InductionStatusInvalid, "Teacher has induction status: #{pending_induction_submission.trs_induction_status}"
    end
  end
end
