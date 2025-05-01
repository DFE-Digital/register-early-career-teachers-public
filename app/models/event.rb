class Event < ApplicationRecord
  EVENT_TYPES = %w[
    import_from_dqt
    induction_extension_created
    induction_extension_updated
    induction_period_closed
    induction_period_deleted
    induction_period_opened
    induction_period_reopened
    induction_period_updated
    teacher_fails_induction
    teacher_imported_from_trs
    teacher_induction_status_reset
    teacher_name_updated_by_trs
    teacher_passes_induction
    teacher_trs_attributes_updated
    teacher_trs_induction_status_updated
    teacher_registered_as_mentor
    teacher_registered_as_ect
    teacher_starts_mentoring
    teacher_starts_being_mentored
  ].freeze

  belongs_to :teacher
  belongs_to :appropriate_body
  belongs_to :induction_period
  belongs_to :induction_extension

  belongs_to :school
  belongs_to :ect_at_school_period
  belongs_to :mentor_at_school_period
  belongs_to :training_period
  belongs_to :mentorship_period
  belongs_to :school_partnership
  belongs_to :lead_provider
  belongs_to :delivery_partner
  belongs_to :user

  belongs_to :author, class_name: 'User'

  validates :heading, presence: true
  validates :happened_at, presence: true
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  validate :check_author_present
  validate :event_happened_in_the_past

  scope :earliest_first, -> { order(happened_at: 'asc') }
  scope :latest_first, -> { order(happened_at: 'desc') }

private

  def check_author_present
    return if author_type == 'system'
    return if author_id.present? || author_email.present?

    errors.add(:base, 'Author is missing')
  end

  def event_happened_in_the_past
    return if happened_at.blank?
    return if happened_at <= Time.zone.now

    errors.add(:happened_at, 'Event must have already happened')
  end
end
