module API::Concerns::TrainingValidatable
  extend ActiveSupport::Concern

  def teacher_provider_metadata(teacher:, lead_provider:)
    @metadata ||= teacher.lead_provider_metadata.find_by(lead_provider_id:) if teacher && lead_provider
  end

  def latest_provider_training_period(teacher:, teacher_type:, lead_provider:)
    return unless metadata = teacher_provider_metadata(teacher:, lead_provider:, teacher_type:)

    @latest_provider_training_period ||= case teacher_type
                                         when :ect
                                           metadata.latest_ect_training_period
                                         when :mentor
                                           metadata.latest_mentor_training_period
                                         end
    end

    def training_status
      @training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period: latest_provider_training_period) if training_period
    end
  end
end
