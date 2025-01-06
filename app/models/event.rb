class Event < ApplicationRecord
  EVENT_TYPES = %i[
    appropriate_body_claims_teacher
    teacher_name_updated_by_trs
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

  validate :check_author_present
  validate :event_happened_in_the_past

private

  def check_author_present
    return if author_id.present? || author_email.present?

    errors.add(:base, 'Author is missing')
  end

  def event_happened_in_the_past
    return if happened_at.blank?
    return if happened_at <= Time.zone.now

    errors.add(:happened_at, 'Event must have already happened')
  end
end