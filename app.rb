require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require "./lib/music/music.rb"
require "./lib/google.rb"
require "./models/dj_system-api.rb"

require './base'
require './routes/mc'
require './routes/room'

class DjSystemApi < Base
  CORS_DOMAINS = ENV['CORS_DOMAINS'].split(',')

  options '*' do
    response.headers["Access-Control-Allow-Methods"] = "GET, PUT, POST, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Origin"] = CORS_DOMAINS.find { |domain| @env["HTTP_ORIGIN"] == domain } || CORS_DOMAINS.first
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token, X-Requested-With, api-token"
    response.headers["Access-Control-Allow-Credentials"] = "true"
  end

  before do
    response.headers["Access-Control-Allow-Origin"] = CORS_DOMAINS.find { |domain| @env["HTTP_ORIGIN"] == domain } || CORS_DOMAINS.first
    response.headers["Access-Control-Allow-Credentials"] = "true"

    if @env["HTTP_API_TOKEN"]
      begin
        decoded_token = JWT.decode(@env["HTTP_API_TOKEN"], ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
        @env["user"] = User.find_by(id: decoded_token[0]['user_id'])
        next unless @env["user"]
        @env["user"].access_tokens.each do |token|
          case token.provider
          when 'google'
            @env["google"] = Google.new(token.access_token, token.refresh_token)
          when 'spotify'
            @env["spotify"] = MusicApi::SpotifyApi.new(token.access_token, token.refresh_token)
          end
        end
      rescue => e
        p e.class
        p e.message
        p e.backtrace.join("\n")
      end
    end
  end

  get "/" do
    "DJ GASSI API"
  end

  bind_router "/mc", McRouter
  bind_router "/room", RoomRouter
end
