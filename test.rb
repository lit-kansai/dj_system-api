require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
Dotenv.load
require "./music/music.rb"

enable :sessions

SPOTIFY_CLIENT_ID = ENV["SPOTIFY_CLIENT_ID"]
SPOTIFY_CLIENT_SECRET = ENV["SPOTIFY_CLIENT_SECRET"]
REDIRECT_URL = "http://localhost:4567/api/spotify/callback"

before do
  request['music_api'] = Music::SpotifyApi.new(session[:spotify_token]) if session[:spotify_token]
end

get '/' do
  "<a href=\"#{Music::SpotifyApi.get_redirect_url(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, REDIRECT_URL)}\">Spotifyログイン</a>"
end

get '/menu' do
  redirect '/' unless session[:spotify_token]
  '<a href="/api/search?q=しわあわせ">曲検索（しわあわせ）</a><br>
  <a href="/api/playlists">プレイリスト一覧</a>'
end

get '/api/search' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].search(params[:q]).to_json
end

get '/api/playlists' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].playlists.to_json
end

get '/api/spotify/callback' do
  token = Music::SpotifyApi.get_token_by_code(params['code'], 'test', REDIRECT_URL)
  session[:spotify_token] = token['access_token']
  redirect '/menu'
end