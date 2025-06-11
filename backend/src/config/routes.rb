Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :messages, only: [:index, :create] do
        collection do
          delete 'reset'
        end
      end

      # セッション一覧と個別セッションのメッセージ取得を追加
      resources :chat_sessions, only: [:index, :create, :destroy, :update] do
        member do
          get 'messages' # 例: GET /api/v1/chat_sessions/1/messages
        end
      end
    end
  end
end
