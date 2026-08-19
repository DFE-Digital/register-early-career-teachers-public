class AddTRSResponseToTeachers < ActiveRecord::Migration[8.1]
  def change
    create_enum :trs_responses, %w[ok not_found gone permanent_redirect]

    change_table :teachers, bulk: true do |t|
      t.enum :trs_response, enum_type: :trs_responses
      t.string :trs_redirected_to
    end
  end
end
