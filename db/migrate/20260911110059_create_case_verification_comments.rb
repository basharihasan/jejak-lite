class CreateCaseVerificationComments < ActiveRecord::Migration[8.1]
  def change
    create_table :case_verification_comments do |t|
      t.bigint :clinical_case_id, null: false
      t.bigint :user_id, null: false
      t.string :action, null: false
      t.text :body

      t.timestamps
    end

    add_index :case_verification_comments, :clinical_case_id
    add_index :case_verification_comments, :user_id

    safety_assured do
      add_foreign_key :case_verification_comments, :clinical_cases
      add_foreign_key :case_verification_comments, :users
    end
  end
end
