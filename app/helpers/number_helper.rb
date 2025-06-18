module NumberHelper
  include ActionView::Helpers::NumberHelper

  def number_to_pounds(number)
    number = 0 if number.zero?

    number_to_currency number, precision: 2, unit: "£"
  end
end
