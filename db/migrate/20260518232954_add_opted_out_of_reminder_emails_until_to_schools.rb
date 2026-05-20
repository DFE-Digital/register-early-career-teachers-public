class AddOptedOutOfReminderEmailsUntilToSchools < ActiveRecord::Migration[8.1]
  def change
    add_column :schools, :opted_out_of_reminder_emails_until, :date
  end
end
