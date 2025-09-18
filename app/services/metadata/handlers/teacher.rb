module Metadata::Handlers
  class Teacher < Base
    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def refresh_metadata!
      upsert_metadata!
    end

    class << self
      def destroy_all_metadata!
        truncate_models!(Metadata::Teacher)
      end
    end

  private

    def upsert_metadata!
      metadata = Metadata::Teacher.find_or_initialize_by(teacher:)

      changes = {
        induction_started_on: induction_started_on(teacher:),
        induction_finished_on: induction_finished_on(teacher:),
      }

      upsert(metadata, **changes)
    end

    def induction_started_on(teacher:)
      teacher.induction_periods
        .order(started_on: :asc)
        .limit(1)
        .pick(:started_on)
    end

    def induction_finished_on(teacher:)
      teacher.induction_periods
        .where.not(outcome: nil)
        .order(finished_on: :desc)
        .limit(1)
        .pick(:finished_on)
    end
  end
end
