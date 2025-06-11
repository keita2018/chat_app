module Api
  module V1
    class MessagesController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        session_id = params[:chat_session_id]
        messages = Message.where(chat_session_id: session_id).order(created_at: :asc)
        render json: messages
      end

      def create
        user_message = params[:message]
        chat_session_id = params[:chat_session_id]
        model = params[:model] || "llama-3.3-70b-versatile"

        begin
          # 1. 過去の履歴を取得
          past_messages = Message.where(chat_session_id: chat_session_id)
                                 .order(:created_at)
                                 .last(20) # 必要に応じて調整
                                 .map { |msg| { role: msg.role, content: msg.content } }

          # 2. 新しいユーザーメッセージを履歴に追加
          full_messages = past_messages + [{ role: "user", content: user_message[:content] }]

          # 3. Groq API に問い合わせ
          response_content = fetch_groq_response(full_messages, model)

          # 4. メッセージを保存
          Message.create!(
            role: "user",
            content: user_message[:content],
            chat_session_id: chat_session_id
          )

          Message.create!(
            role: "assistant",
            content: response_content,
            chat_session_id: chat_session_id
          )

          # 5. 応答を返す
          render json: {
            assistant: {
              role: "assistant",
              content: response_content
            }
          }, status: :ok

        rescue => e
          Rails.logger.error "メッセージ保存またはAPI呼び出しでエラー: #{e.message}"
          render json: { error: "メッセージ送信に失敗しました: #{e.message}" }, status: :internal_server_error
        end
      end

      def reset
        Message.delete_all
        render json: { status: 'ok' }
      end

      private

      def fetch_groq_response(messages, model)
        response = HTTP.auth("Bearer #{ENV['GROQ_API_KEY']}")
                      .post("https://api.groq.com/openai/v1/chat/completions", json: {
                        model: model,
                        messages: messages
                      })

        json = JSON.parse(response.body.to_s)
        json.dig("choices", 0, "message", "content") || "No response"
      end

      def message_params
        params.require(:message).permit(:role, :content)
      end
    end
  end
end
