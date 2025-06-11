# backend/Dockerfile
FROM ruby:3.2

# 必要なパッケージをインストール
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# 作業ディレクトリ
WORKDIR /app

# RailsプロジェクトのGemfileだけコピーしてbundle install
COPY ./src/Gemfile ./src/Gemfile.lock ./
RUN bundle install

# アプリケーション全体をコピー
COPY ./src .

# ポート3000番を開放
EXPOSE 3000

# railsサーバー起動（productionなら変える）
CMD ["rails", "server", "-b", "0.0.0.0"]
