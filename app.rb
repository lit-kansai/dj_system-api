require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require "./lib/music/music.rb"
require "./lib/google.rb"
require "./models/dj_system-api.rb"

require "net/http"

Dotenv.load
use Rack::JSONBodyParser

configure do
  set :protection, :except => [:json_csrf]
end

CORS_DOMAINS = ["http://dj.lit-kansai-mentors.com", "https://dj.lit-kansai-mentors.com", "http://localhost:3000", "http://127.0.0.1:3000"]

options '*' do
    response.headers["Access-Control-Allow-Methods"] = "GET, PUT, POST, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Origin"] = CORS_DOMAINS.find { |domain| request.env["HTTP_ORIGIN"] == domain } || CORS_DOMAINS.first
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token, X-Requested-With, api-token"
    response.headers["Access-Control-Allow-Credentials"] = "true"
end

before do
    response.headers["Access-Control-Allow-Origin"] = CORS_DOMAINS.find { |domain| request.env["HTTP_ORIGIN"] == domain } || CORS_DOMAINS.first
    response.headers["Access-Control-Allow-Credentials"] = "true"

    if request.env["HTTP_API_TOKEN"]
        begin
            decoded_token = JWT.decode(request.env["HTTP_API_TOKEN"], ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
            @user = User.find_by(id: decoded_token[0]['user_id'])
            return unless @user
            @user.access_tokens.each do |token|
                puts token.provider
                case token.provider
                when 'google'
                    @google = Google.new(token.access_token)
                when 'spotify'
                    @spotify = Spotify.new(token.access_token)
                end
            end
        rescue => e # 例外オブジェクトを代入した変数。
            session.clear
        end
    end
end

get '/' do
    "DJ GASSI API"
end

# roomの作成
post "/room" do
    return unauthorized unless @user
    return bad_request("invalid parameters") unless has_params?(params, [:url_name, :room_name, :description])

    room = @user.my_rooms.build(
        users: [@user],
        display_id: params[:url_name],
        name: params[:room_name],
        description: params[:description]
    )
    return internal_server_error("Failed to save") unless room.save

    send_json room
end

# 全room情報取得(管理可能なroomのみ)
get "/room/all" do
    return unauthorized unless @user
    users = @user.rooms.as_json(include: [:users])
    send_json users
end

# room個別情報表示
get "/room/:id" do
    return bad_request("invalid parameters") unless has_params?(params, [:id])

    room = @user.rooms.find_by(id: params[:id])
    return not_found_error if room.nil?

    send_json room.as_json(include: [:users, :letters])
end

# room個別情報更新
put "/room/:id" do
    return unauthorized unless @user
    return bad_request("invalid parameters") unless has_params?(params, [:id])

    room = @user.rooms.find_by(id: params[:id])
    return not_found_error unless room

    room.display_id = params[:url_name] if params.has_key?(:url_name)
    room.name = params[:room_name] if params.has_key?(:room_name)
    room.description = params[:description] if params.has_key?(:description)
    return bad_request("Failed to save") unless room.save

    send_json room.as_json(include: [:users])
end

# room個別削除
delete "/room/:id" do
    return unauthorized unless @user
    return bad_request("invalid parameters") unless has_params?(params, [:id])

    room = @user.rooms.find_by(id: params[:id])
    return not_found_error unless room

    room.destroy

    data = {
        code: "200",
        ok: true
    }
    send_json data
end

# リクエスト送信
post "/room/:id/request" do
    return bad_request("invalid parameters") unless has_params?(params, [:id, :musics, :radio_name, :message])

    room = @user.rooms.find_by(id: params[:id])
    return not_found_error unless room

    letter = room.letters.build(
        radio_name: params[:radio_name],
        message: params[:message],
    )

    return internal_server_error("Failed to save") unless letter.save

    musics.each do |music|
        letter.music.create(provided_music_id: music)
    end

    # 音楽API呼び出し

    data = {
        code: "200",
        ok: true
    }
    send_json data
end

# 音楽サービスとの連携
get "/music/search" do

    #Header情報取得
    headers = request.env.select { |k, v| k.start_with?('HTTP_') }

    headers.each do |k, v|
        puts "#{k} -> #{v}"
    end



    # tokenを複合化
    JWT.decode(token, rsa_public, true, { algorithm: 'RS256' })

    spotify_api = MusicApi::SpotifyApi.new("access_token")

    puts spotify_api
end

# ユーザー(管理者&MC)ログイン(新規作成も)
get "/user/login" do
    return bad_request("invalid parameters") unless has_params?(params, [:redirect_url])

    data = { redirect_url: Google.get_oauth_url(params['redirect_url']) }
    send_json data
end

# Googleログイン後に呼び出す。クエリなどをサーバー側に渡す。
post "/user/loggedInGoogle" do
    return bad_request("invalid parameters") unless has_params?(params, [:code, :redirect_url])

    google_token = Google.get_token_by_code(params['code'], params['redirect_url'])
    return bad_request unless google_token['access_token']

    google_id = Google.new(google_token['access_token']).profile['id']
    return bad_request unless google_id

    user = User.find_or_create_by(google_id: google_id)
    user.access_tokens.find_or_create_by(provider: 'google').update(access_token: google_token['access_token'], refresh_token: google_token['refresh_token'])
    token = JWT.encode({ user_id: user.id }, ENV['JWT_SECRET'], 'HS256')
    
    data = { api_token: token, user_id: user.id }
    send_json data
end

# ユーザー(管理者&MC)情報取得
get "/user/:userId" do
    user = User.find_by(userId: params[:userId])
    if user
        data = {
            name: user.name,
            avatar_url: user.avatar_url,
            is_admin: user.is_admin
        }

        data.to_json

        status 200
    else
        status 404
    end
end

# ユーザー(管理者&MC)情報更新
get "/user/:userId" do
    user = User.find_by(userId: params[:userId])
    user.update(
        name: params[:name],
        avatar_url: params[:avatar_url],
        is_admin: params[:is_admin]
    )

    if user.save
        data = {
            name: user.name,
            avatar_url: user.avatar_url,
            is_admin: user.is_admin
        }

        data.to_json

        status 200
    else
        status 404
    end
end

# ユーザー(管理者&MC)情報削除
get "/user/:userId" do
    user = User.find_by(userId: params[:userId])
    user.delete

    if user.save
        status 200
    else
        status 404
    end
end

# Spotifyとの連携
get "/user/link/spotify" do

    return bad_request("invalid parameters") unless has_params?(params, [:redirect_url])

    data = { redirect_url: MusicApi::SpotifyApi.get_oauth_url(params['redirect_url']) }
    send_json data

end

post "/user/loggedInSpotify" do
    return unauthorized unless @user
    return bad_request("invalid parameters") unless has_params?(params, [:code, :redirect_url])

    spotify_token = MusicApi::SpotifyApi.get_token_by_code(params['code'], params['redirect_url'])
    return internal_server_error("failed to get token") unless spotify_token['access_token']

    @user.access_tokens.find_or_create_by(provider: 'spotify').update(access_token: spotify_token['access_token'], refresh_token: spotify_token['refresh_token'])

    data = { ok: true }
    send_json data
end

private
    def send_json(data)
        content_type :json
        data.to_json
    end

    def has_params?(params, keys)
        keys.all? { |key| params.has_key?(key) && !params[key].empty? }
    end

    # error

    def bad_request(message=nil)
        data = {
            "message": message || "Bad Request",
            "status": 400
        }
        status 400
        send_json data
    end

    def unauthorized(message=nil)
        data = {
            "message": message || "Unauthorized",
            "status": 401
        }
        status 401
        send_json data
    end

    def forbidden(message=nil)
        data = {
            "message": message || "Forbidden",
            "status": 403
        }
        status 403
        send_json data
    end

    def not_found_error(message=nil)
        data = {
            "message": message || "Not Found",
            "status": 404
        }
        status 404
        send_json data
    end

    def internal_server_error(message=nil)
        data = {
            "message": message || "Internal Server Error",
            "status": 500
        }
        status 500
        send_json data
    end

    def message_error
        data = {
            code: "---",
            message: "Error"
        }
        return data
    end

# アクセストークン → ユーザーがアプリに対して他あしくログインしていることを示すトークン（googleOathに紐づけられるトークン）
# リフレッシュトークン → セッション的なトークン
# APIトークン → Spotify

# jwt は　ログインの時に生成されるトークン　これを投げ合う　headerで取得git branch
