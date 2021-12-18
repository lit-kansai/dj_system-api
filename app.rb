require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require "./lib/music/music.rb"
require "./lib/google.rb"

require "net/http"

require "jwt"
require "openssl"
require "base64"

Dotenv.load

before do

end
 
get '/' do
    "Hello World!"
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
        end

    # error
    else
        data = message_error
    end
    
    data.to_json
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
