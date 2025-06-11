class CreateChatSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_sessions do |t|
      t.string :title

      t.timestamps
    end
  end
end
