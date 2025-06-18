# PendingInductionSubmission will contain data submitted by appropriate bodies
# containing induction information about a ECT.
#
# It is intended to be a short-lived record that we will process, verify and
# eventually write to the actual database before deleting the record here.
class PendingInductionSubmission < ApplicationRecord
  VALID_NUMBER_OF_TERMS = { min: 0, max: 16 }.freeze
  include Interval
  include SharedInductionPeriodValidation
  include SharedNumberOfTermsValidation

  attribute :confirmed

  enum :outcome, { pass: "pass", fail: "fail" }

  # Scopes
  scope :passed, -> { without_errors.pass.where.not(finished_on: nil, delete_at: nil) }
  scope :failed, -> { without_errors.fail.where.not(finished_on: nil, delete_at: nil) }

  scope :released, -> { without_errors.where(outcome: nil, started_on: nil).where.not(finished_on: nil, delete_at: nil) }

  scope :claimed, -> { without_errors.where(finished_on: nil).where.not(started_on: nil, delete_at: nil) }

  scope :with_errors, -> { where.not(error_messages: []) }
  scope :without_errors, -> { where(error_messages: []) }
  scope :ready_for_deletion, -> { where(delete_at: ..Time.current) }

  # Associations
  belongs_to :appropriate_body
  belongs_to :pending_induction_submission_batch, optional: true, touch: true

  # Validations
  validates :trn,
            presence: { message: "Enter a TRN" },
            format: {
              with: Teacher::TRN_FORMAT,
              message: "TRN must be 7 numeric digits"
            },
            on: :find_ect

  validates :establishment_id,
            format: {
              with: /\A\d{4}\/\d{3}\z/,
              message: "Enter an establishment ID in the format 1234/567"
            },
            allow_nil: true

  validates :induction_programme,
            inclusion: {
              in: %w[fip cip diy unknown], # pre-2025
              message: "Choose an induction programme"
            },
            on: :register_ect

  validates :training_programme,
            inclusion: {
              in: ::TRAINING_PROGRAMME.keys.map(&:to_s), # post-2025
              message: "Choose an induction training programme"
            },
            on: :register_ect

  validates :started_on,
            presence: { message: "Enter a start date" },
            on: :register_ect

  validates :finished_on,
            presence: { message: "Enter a finish date" },
            on: %i[release_ect record_outcome]

  validates :date_of_birth,
            presence: { message: "Enter a date of birth" },
            inclusion: {
              in: 100.years.ago.to_date..18.years.ago.to_date,
              message: "Teacher must be between 18 and 100 years old",
            },
            on: :find_ect

  validates :confirmed,
            acceptance: { message: "Confirm if these details are correct or try your search again" },
            on: :check_ect

  validates :outcome,
            inclusion: {
              in: ::INDUCTION_OUTCOMES.keys.map(&:to_s),
              message: "Outcome must be either 'passed' or 'failed'"
            },
            on: :record_outcome

  validates :trs_qts_awarded_on,
            presence: { message: "QTS has not been awarded" },
            on: :register_ect

  validate :start_date_after_qts_date, on: :register_ect

  validates :trs_induction_status,
            inclusion: {
              in: %w[None RequiredToComplete Exempt InProgress Passed Failed FailedInWales],
              message: "TRS Induction Status is not known",
            },
            on: :register_ect

  validate :no_future_induction_periods,
           if: -> { started_on.present? },
           on: :register_ect

  validate :no_end_date_before_start_date,
           if: -> { finished_on.present? },
           on: %i[release_ect record_outcome]

  # Instance methods

  # @return [Boolean]
  def exempt?
    trs_induction_status.eql?('Exempt')
  end

  # @return [Boolean]
  def release?
    outcome.nil?
  end

  # @return [Boolean] capture multiple error messages and reset before saving
  def playback_errors
    assign_attributes(
      induction_programme: nil,
      training_programme: nil,
      outcome: nil,
      started_on: nil,
      finished_on: nil,
      number_of_terms: nil,
      error_messages: errors.messages.values.flatten
    )
    errors.clear
    save!
  end

  # @return [nil, Teacher]
  def teacher
    @teacher ||= Teacher.find_by(trn:)
  end

  def training_programme
    super || ::PROGRAMME_MAPPER[induction_programme]
  end

private

  def start_date_after_qts_date
    return if trs_qts_awarded_on.blank?

    ensure_start_date_after_qts_date(trs_qts_awarded_on)
  end

  def no_future_induction_periods
    return if teacher.blank?

    latest_date_of_induction = teacher.induction_periods.maximum(:finished_on)

    return unless latest_date_of_induction

    if started_on <= latest_date_of_induction
      errors.add(:started_on, "Enter a start date after the last induction period finished (#{latest_date_of_induction.to_fs(:govuk)})")
    end
  end

  # Bulk CSV outcomes may attempt this. Error message only seen in failed CSV downloads
  def no_end_date_before_start_date
    return if teacher.blank?

    latest_date_of_induction = teacher.induction_periods.maximum(:started_on)

    return unless latest_date_of_induction

    if finished_on <= latest_date_of_induction
      errors.add(:finished_on, "Induction end date must be after the induction start date (#{latest_date_of_induction.to_fs(:govuk)})")
    end
  end
end
