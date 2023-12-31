class CreateUserMeetings < ActiveRecord::Migration[7.0]
  def change
    create_table :user_meetings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :meeting, null: false, foreign_key: true
      t.boolean :is_requestor

      t.timestamps
    end
  end
end
