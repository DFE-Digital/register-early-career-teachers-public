class LeadProviderMentorshipStatus < ApplicationRecord
  belongs_to :mentorship_period
  belongs_to :lead_provider

  enum :status,
       %w[
         no-access-required
         access-and-support-only
         available-to-train
       ].index_by(&:itself),
       validate: true,
       prefix: true

  enum :reason,
       %w[
         mentorship-expired
         ect-finished-training-with-provider
         completed-training
         available-to-train
         mentor-training-elsewhere
         mentor-not-currently-training
         no-known-training
       ].index_by(&:itself),
       validate: true,
       prefix: true

  before_validation :assign_status_and_reason, on: :create

  validates :mentorship_period, :lead_provider, presence: true
  validates :status, :reason, presence: true
  validates :lead_provider_id, uniqueness: { scope: :mentorship_period_id }

  def refresh!
    assign_status_and_reason
    save!
  end

private

  def assign_status_and_reason
    return unless mentorship_period&.mentor&.teacher && lead_provider

    self.status, self.reason = status_and_reason
  end

  def status_and_reason
    return %w[no-access-required mentorship-expired] if mentorship_period.finished?

    mentee_training_periods_for_lead_provider = mentorship_period.mentee.training_periods.select { it.lead_provider&.id == lead_provider_id }

    return %w[no-access-required ect-finished-training-with-provider] if mentee_training_periods_for_lead_provider.any? && mentee_training_periods_for_lead_provider.all?(&:finished?)
    return %w[access-and-support-only completed-training] if mentorship_period.mentor.teacher.mentor_became_ineligible_for_funding_on.present?

    mentor_training_periods = mentorship_period.mentor.training_periods
    current_or_future_mentor_training_periods = mentor_training_periods.select do
      it.unfinished? || it.leaving_today_or_in_future?
    end

    return %w[available-to-train available-to-train] if current_or_future_mentor_training_periods.any? { it.lead_provider&.id == lead_provider_id }
    return %w[access-and-support-only mentor-training-elsewhere] if current_or_future_mentor_training_periods.any?
    return %w[access-and-support-only mentor-not-currently-training] if mentor_training_periods.any?

    %w[access-and-support-only no-known-training]
  end
end
