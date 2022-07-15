require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require "./lib/music/music.rb"
require "./lib/google.rb"
require "./models/dj_system-api.rb"

require './base'
require './routes/mc'

class DjSystemApi < Base
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

    if @env["HTTP_API_TOKEN"]
      begin
        decoded_token = JWT.decode(request.env["HTTP_API_TOKEN"], ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
        @env["user"] = User.find_by(id: decoded_token[0]['user_id'])
        return unless @env["user"]
        @env["user"].access_tokens.each do |token|
          case token.provider
          when 'google'
            @env["google"] = Google.new(token.access_token)
          when 'spotify'
            @env["spotify"] = MusicApi::SpotifyApi.new(token.access_token, token.refresh_token)
          end
        end
      rescue => e
        error e
      end
    end
  end

  get "/" do
    "DJ GASSI API"
  end

  # 楽曲検索
  get "/room/:room_id/music/search" do
    room = Room.find_by(display_id: params[:room_id])
    return not_found_error unless room
    
    case room.provider
    when 'spotify'

    end
  end

  # リクエスト送信
  post "/room/:room_id/request" do
    return bad_request("invalid parameters") unless has_params?(params, [:musics, :radio_name, :message])

    room = Room.find_by(display_id: params[:room_id])
    return not_found_error unless room

    letter = room.letters.build(
      radio_name: params[:radio_name],
      message: params[:message],
    )

    return internal_server_error("Failed to save") unless letter.save

    params[:musics].each do |music|
      token = room.master.access_tokens.find_by(provider: room.provider)
      next unless token

      case room.provider
      when 'spotify'
        spotify = MusicApi::SpotifyApi.new(token.access_token, token.refresh_token)
        track = spotify.get_track(music)
        next unless track

        letter.musics.build(
          provided_music_id: track['id'],
          name: track['name'],
          artist: track['artists'],
          album: track['album'],
          thumbnail: track['thumbnail'],
          duration: track['duration'],
        )
        spotify.add_track_to_playlist(room.playlist_id, music)
      else
      end
    end

    send_json(ok: true)
  end

  bind_router "/mc", McRouter
end
