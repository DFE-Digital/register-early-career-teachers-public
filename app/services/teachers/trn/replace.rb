module Teachers
  module TRN
    class Replace
      def initialize(teacher:, new_trn: nil, author: nil)
        raise ArgumentError, "new_trn must not be blank when supplied" if new_trn.blank? && !new_trn.nil?

        @teacher = teacher
        @author = author || Events::SystemAuthor.new
        @new_trn = new_trn
      end

      def replace!
        teacher.with_lock do
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
        end

        Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
      end

    private

      attr_reader :teacher, :author

      def eligibility
        Teachers::TRN::Eligibility.new(teacher:, new_trn: @new_trn)
      end

      def new_trn
        @new_trn || teacher.trs_redirected_to
      end
    end
  end
end
