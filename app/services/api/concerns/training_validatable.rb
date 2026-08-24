module API::Concerns::TrainingValidatable
  extend ActiveSupport::Concern

  included do
    include API::Concerns::LeadProviderValidatable
    include API::Concerns::TeacherValidatable
  end

  def training_period
    @training_period ||= latest_provider_training_period
  end

  def training_status
    @training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period:) if training_period
  end

  def teacher_lead_provider_metadata
    return unless teacher && lead_provider

    @teacher_lead_provider_metadata ||= teacher.lead_provider_metadata.find_by(lead_provider_id: lead_provider.id)
  end

  def latest_provider_training_period
    return unless teacher_lead_provider_metadata

    @latest_provider_training_period ||= case teacher_type
                                         when :ect
                                           teacher_lead_provider_metadata.latest_ect_training_period
                                         when :mentor
                                           teacher_lead_provider_metadata.latest_mentor_training_period
                                         end
  end
end
