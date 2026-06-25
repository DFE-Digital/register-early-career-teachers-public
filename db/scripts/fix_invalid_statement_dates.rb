# We have some statements where the payment date is on or before the deadline date.
# This script will correct these by moving the payment date to the last day
# of the following month.

ActiveRecord::Base.transaction do
  invalid_statements = Statement.where("payment_date <= deadline_date")
  changes = []

  invalid_statements.find_each do |statement|
    new_payment_date = statement.deadline_date.next_month.end_of_month
    changes << { id: statement.id, deadline_date: statement.deadline_date, old_payment_date: statement.payment_date, new_payment_date: }
    statement.update!(payment_date: new_payment_date)
  end

  Rails.logger.debug("Updated statements:")
  changes.each do |it|
    Rails.logger.debug("Statement ID: #{it[:id]}, Deadline Date: #{it[:deadline_date]}, Old Payment Date: #{it[:old_payment_date]}, New Payment Date: #{it[:new_payment_date]}")
  end

  raise "Failed to fix all statements" if Statement.where("payment_date <= deadline_date").exists?
end
