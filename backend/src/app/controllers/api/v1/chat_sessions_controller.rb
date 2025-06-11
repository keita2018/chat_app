module Api
  module V1
    class ChatSessionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        sessions = ChatSession.order(created_at: :desc)
        render json: sessions
      end

      def create
        session = ChatSession.create(title: params[:title] || "新しいチャット")
        render json: session, status: :created
      end

      def destroy
        chat_session = ChatSession.find(params[:id])
        if chat_session
          chat_session.destroy
          head :no_content
        else
          render json: { error: 'Not found' }, status: :not_found
        end
      end

      def update
        chat_session = ChatSession.find(params[:id])
        if chat_session.update(title: params[:title])
            render json: chat_session
        else
            render json: { error: 'Update failed' }, status: :unprocessable_entity
        end
      end

      def messages
        chat_session = ChatSession.find(params[:id])
        messages = chat_session.messages.order(:created_at)

        render json: messages
      end
    end
  end
end
