class AddCourseIdentifierAndReasonToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :course_identifier, :string
    add_column :events, :reason, :string
  end
end
