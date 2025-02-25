module SharedNumberOfTermsValidation
  extend ActiveSupport::Concern

  included do
    validates :number_of_terms,
              numericality: { message: "Number of terms must be a number with up to 1 decimal place", allow_nil: true },
              terms_range: true,
              presence: {
                message: "Enter a number of terms",
                if: -> { respond_to?(:finished_on) && finished_on.present? }
              },
              absence: {
                message: "Delete the number of terms if the induction has no end date",
                if: -> { respond_to?(:finished_on) && finished_on.blank? }
              }

    validate :validate_number_of_terms_decimal_places
  end

private

  def validate_number_of_terms_decimal_places
    return if number_of_terms.nil?

    # Convert float to string and check if it matches the pattern of up to 1 decimal place
    unless number_of_terms.to_s.match?(/\A\d+(\.\d)?\z/)
      errors.add(:number_of_terms, "Terms can only have up to 1 decimal place")
    end
  end
end
