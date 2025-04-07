class Event < ApplicationRecord
  EVENT_TYPES = %w[
    admin_creates_induction_period
    induction_period_updated
    admin_fails_teacher_induction
    admin_passes_teacher_induction
    admin_reverts_teacher_claim
    admin_deletes_induction_period
    appropriate_body_claims_teacher
    appropriate_body_releases_teacher
    appropriate_body_fails_teacher
    appropriate_body_passes_teacher
    teacher_name_updated_by_trs
    teacher_induction_status_updated_by_trs
    teacher_attributes_updated_from_trs
    teacher_imported_from_trs
    import_from_dqt
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
  belongs_to :provider_partnership
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
