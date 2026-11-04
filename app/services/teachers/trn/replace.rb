module Teachers
  module TRN
    class Replace
      def initialize(teacher:, new_trn: nil, author: nil)
        @teacher = teacher
        @new_trn = new_trn
        @author = author || Events::SystemAuthor.new
      end

      def replace!
        return unless eligibility.can_be_replaced?

        ActiveRecord::Base.transaction do
          old_trn = teacher.trn
          replacement_trn = new_trn

          teacher.update!(
            trn: replacement_trn,
            trs_redirected_to: nil,
            trs_response: "ok"
          )

          Events::Record.record_teacher_trn_replaced_event!(
            teacher:,
            author:,
            old_trn:,
            new_trn: replacement_trn
          )
        end

        Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
      end

    private

      attr_reader :teacher, :author

      def new_trn
        return teacher.trs_redirected_to if teacher.trs_response_permanent_redirect?

        @new_trn
      end

      def eligibility
        Teachers::TRN::Eligibility.new(teacher:, new_trn:)
      end
    end
  end
end
