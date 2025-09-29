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

      changes = {}

      changes[:first_became_eligible_for_ect_training_at] = Time.zone.now if became_eligible_for_ect_training?(teacher:)
      changes[:first_became_eligible_for_mentor_training_at] = Time.zone.now if became_eligible_for_mentor_training?(teacher:)

      upsert(metadata, **changes) if changes.any?
    end

    def became_eligible_for_ect_training?(teacher:)
      teacher.eligible_for_ect_training? && teacher.first_became_eligible_for_ect_training_at.nil?
    end

    def became_eligible_for_mentor_training?(teacher:)
      teacher.eligible_for_mentor_training? && teacher.first_became_eligible_for_mentor_training_at.nil?
    end
  end
end
