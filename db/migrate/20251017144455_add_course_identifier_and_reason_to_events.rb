class AddCourseIdentifierAndReasonToEvents < ActiveRecord::Migration[8.0]
  def change
    change_table :events, bulk: true do |t|
      t.string :course_identifier
      t.string :reason
    end
  end
end
