# PendingInductionSubmission will contain data submitted by appropriate bodies
# containing induction information about a ECT.
#
# It is intended to be a short-lived record that we will process, verify and
# eventually write to the actual database before deleting the record here.
class PendingInductionSubmission < ApplicationRecord
  include Interval
  include SharedInductionPeriodValidation

  attribute :confirmed

  enum :outcome, { pass: "pass", fail: "fail" }

  # Associations
  belongs_to :appropriate_body

  # Validations
  validates :trn,
            presence: { message: "Enter a TRN" },
            format: { with: Teacher::TRN_FORMAT, message: "TRN must be 7 numeric digits" },
            on: :find_ect

  validates :establishment_id,
            format: { with: /\A\d{4}\/\d{3}\z/, message: "Enter an establishment ID in the format 1234/567" },
            allow_nil: true

  validates :induction_programme,
            inclusion: { in: %w[fip cip diy],
                         message: "Choose an induction programme" },
            on: :register_ect

  validates :started_on,
            presence: { message: "Enter a start date" },
            on: :register_ect

  validates :finished_on,
            presence: { message: "Enter a finish date" },
            on: %i[release_ect record_outcome]

  validates :number_of_terms,
            inclusion: {
              in: 0..16, message: "Terms must be between 0 and 16", if: -> { finished_on.present? }
            },
            presence: {
              message: "Enter a number of terms", if: -> { finished_on.present? }
            },
            absence: {
              message: "Delete the number of terms if the induction has no end date", if: -> { finished_on.blank? }
            },
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
              in: PendingInductionSubmission.outcomes.keys,
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
  validate :no_future_induction_periods, if: -> { started_on.present? }, on: :register_ect

  def exempt?
    trs_qts_status_description == "Exempt"
  end

private

  def start_date_after_qts_date
    return if trs_qts_awarded_on.blank?

    ensure_start_date_after_qts_date(trs_qts_awarded_on)
  end

  def no_future_induction_periods
    teacher = Teacher.find_by(trn:)

    return if teacher.blank?

    latest_date_of_induction = teacher.induction_periods.maximum(:finished_on)

    return unless latest_date_of_induction

    if started_on <= latest_date_of_induction
      errors.add(:started_on, "Enter a start date after the last induction period finished (#{latest_date_of_induction.to_fs(:govuk)})")
    end
  end
end
