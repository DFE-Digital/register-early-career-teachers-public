class AddIndexToRedirectedTeacher < ActiveRecord::Migration[8.1]
  def change
    add_index :teachers, :trs_redirected_to, where: "trs_redirected_to IS NOT NULL"
  end
end
