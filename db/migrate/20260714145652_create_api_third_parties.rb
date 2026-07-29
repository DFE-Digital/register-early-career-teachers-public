class CreateAPIThirdParties < ActiveRecord::Migration[8.1]
  def change
    create_table :api_third_parties do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :email, null: false, index: { unique: true }
      t.timestamps
    end

    add_reference :api_tokens, :api_third_party, null: true, foreign_key: true
  end
end
