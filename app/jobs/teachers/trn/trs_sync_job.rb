module Teachers
  module TRN
    class TRSSyncJob < ApplicationJob
      after_perform do |job|
        teacher = job.arguments.first.fetch(:teacher)
        Teachers::SyncTeacherWithTRSJob.set(wait: 5.minutes).perform_later(teacher:)
      end

      def perform(teacher:, teacher_started_induction_on:)
        if teacher_started_induction_on.present?
          BeginECTInductionJob.perform_now(trn: teacher.trn, start_date: teacher_started_induction_on)
        end
      end
    end
  end
end
