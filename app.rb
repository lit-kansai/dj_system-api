require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require 'sinatra/activerecord'
require './models/dj_system-api.rb'

require "./lib/music/music.rb"
require "./lib/google.rb"

require "net/http"
require "jwt"
require "openssl"
require "base64"

require "pry" if development?

Dotenv.load

enable :sessions

before do

end
 
get '/' do
    "<a href=\"#{Google.get_oauth_url(ENV['GOOGLE_REDIRECT_URL'])}\">Googleログイン</a>"
end

get "/test" do
    data = nil
    if data
        data = {
            status: "OK"
        }
    else
        data = message_404
    end


    #Header情報取得
    headers = request.env.select { |k, v| k.start_with?('HTTP_') }

    headers.each do |k, v|
        puts "#{k} -> #{v}"
    end

    # tokenを複合化
    # JWT.decode(token, rsa_public, true, { algorithm: 'RS256' })

    data.to_json
end

# roomの作成
post "/room" do
    #　Roomの作成
    room = Room.new(
        url_name: params[:url_name],
        room_name: params[:room_name],
        description: params[:description],
        users: params[:users]
    )

    # code:200 Success
    if room.save
        data = {
            url: ""
        }
        status 200
    # error
    else
        data = message_error
    end

    data.to_json
end

# 全room情報取得(管理可能なroomのみ)
get "/room/all" do
    rooms = Room.all
    data = []
    if rooms
        # code: 204 No Content
        if rooms.empty
            data = message_204
        # code: 200 Success
        else 
            rooms.each do |room|
                room_data = {
                    url_name: room.url_name,
                    room_name: room.room_name,
                    description: room.description,
                    users: room.users,
                    created_at: room.created_at,
                    updated_at: room.updated_at
                }
                data.push(room_data)
            end
            status 200
        end

    # error
    else
        data = message_error
    end
    
    data.to_json
end

# room個別情報表示
get "/room/:id" do
    room = Room.find_by(params[:roomId])
    # code: 200 Success
    if room
        data = {
            url_name: room.url_name,
            room_name: room.room_name,
            description: room.description,
            users: room.users,
            created_at: room.created_at,
            updated_at: room.updated_at
        }
        status 200

    # status: 404 Not Found
    else
        status 404
    end
    
    data.to_json
end

# room個別情報更新
put "/room/:roomId" do
    room = Room.find_by(params[:roomId])
    # status: 200 Success
    if room
        room.update(
            url_name: params[:url_name],
            room_name: params[:room_name],
            description: params[:description],
            users: params[:users],
            created_at: params[:created_at],
            updated_at: :params[updated_at]
        )

        # data = {
        #     url_name: room.url_name,
        #     room_name: room.room_name,
        #     description: room.description,
        #     users: room.users,
        #     created_at: room.created_at,
        #     updated_at: room.updated_at
        # }

        status 200

    # status: 404 Not Found
    else
        status 404
    end
    
    data.to_json
end

# room個別削除
delete "/room/:roomId" do
    room = Room.find_by(params[:roomId])
    # status: 200 Success
    if room
        room.destroy

        # data = {
        #     url_name: room.url_name,
        #     room_name: room.room_name,
        #     description: room.description,
        #     users: room.users,
        #     created_at: room.created_at,
        #     updated_at: room.updated_at
        # }
        status 200

    # status: 404 Not Found
    else
        status 404
    end

    data.to_json
end

# リクエスト送信
get "/room/:roomId/request" do
    room = Room.find_by(prams[:roomId])
    # status: 200 Success
    if room
        
        # リクエスト処理
        reqMusic = RequestMusic.create(
            musics: params[:musics],
            radio_name: params[:radio_name],
            message: params[:message]
        )

        if reqMusic
        elsif
            data = message_error
        end

        status 200

    # status: 404 Not Found
    else
        status 404
    end
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

    spotify_api = Music::SpotifyApi.new("access_token")

    puts spotify_api
end

get "/api/google/callback" do

    access_token = Google.get_token_by_code(params['code'], 'test', ENV['GOOGLE_REDIRECT_URL'])
    session[:token_data] = access_token
    session[:google_token] = access_token['access_token']

    redirect '/user/login'
end

# ユーザー(管理者&MC)ログイン(新規作成も)
get "/user/login" do
    
    # 秘密鍵生成
    rsa_private = OpenSSL::PKey::RSA.generate(2048)

    # 公開鍵生成
    rsa_public = rsa_private.public_key

    # 乱数生成
    random = Random.new.rand

    # 秘密鍵で渡し合う乱数
    token_data = {
        random_num: random
    }

    # token_data を暗号化 (秘密鍵でしかできない)
    refresh_token = JWT.encode(token_data, rsa_private, 'RS256')

    # ログイン
    user = User.find_by(google_id: params[:google_id])
    if user == nil
        session[:user] = user.id
    else
        uer = User.create(
            is_admin: params[:is_admin],
            google_id: params[:google_id]
        )

        access_token = session[:token_data]

        AccessToken.create(
            user_id: user.id,
            token_type: access_token['token_type'].to_s,
            access_token: access_token['access_token'],
            refresh_token: refresh_token
        )
    end

    # tokenをheaderに追加
    request.env['HTTP_TOKEN'] = refresh_token

    #Header情報取得
    headers = request.env.select { |k, v| k.start_with?('HTTP_') }

    headers.each do |k, v|
        puts "#{k} -> #{v}"
    end

    data = {
        token: refresh_token,
        random_number: random,
        unlocked: JWT.decode(refresh_token, rsa_private, true, { algorithm: 'RS256' }),
    }

    data.to_json

end

# Googleログイン後に呼び出す。クエリなどをサーバー側に渡す。
# post "/user/loggedInGoogle" do

# end

# ユーザー(管理者&MC)情報取得
get "/user/:userId" do
    user = User.find(id: params[:id])
    if user
        data = {
            is_admin: user.is_admin,
            google_id: user.google_id
        }

        data.to_json

        status 200
    else
        status 404
    end
end

# ユーザー(管理者&MC)情報更新
get "/user/:userId" do
    user = User.find(id: params[:id])
    user.update(
        is_admin: params[:is_admin]
    )

    if user.save
        data = {
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
    user = User.find(id: params[:id])
    user.delete

    if user.save
        status 200
    else
        status 404
    end
end

# Spotifyとの連携
get "/user/link/spotify" do

end

private
    # error
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
