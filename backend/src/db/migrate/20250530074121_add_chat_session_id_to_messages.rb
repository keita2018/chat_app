class AddChatSessionIdToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :chat_session_id, :integer
  end
end
