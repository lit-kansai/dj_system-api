require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
Dotenv.load
require "./lib/music/music.rb"

enable :sessions

SPOTIFY_REDIRECT_URL = "http://localhost:4567/api/spotify/callback"

before do
  request['music_api'] = Music::SpotifyApi.new(session[:spotify_token]) if session[:spotify_token]
end

get '/' do
  "<a href=\"#{Music::SpotifyApi.get_oauth_url(SPOTIFY_REDIRECT_URL)}\">Spotifyログイン</a><br>"
end

# Spotify

get '/menu/spotify' do
  redirect '/' unless session[:spotify_token]
  '<a href="/api/spotify/search?q=しわあわせ">曲検索（しわあわせ）</a><br>
  <a href="/api/spotify/playlists">プレイリスト一覧</a><br>
  <a href="/api/spotify/playlist">プレイリスト詳細</a><br>
  <a href="/api/spotify/playlist/tracks">プレイリスト楽曲一覧</a><br>
  <a href="/api/spotify/create_playlist?name=テスト">プレイリスト作成（テスト）</a><br>
  <a href="/api/spotify/add_track_to_playlist?q=しわあわせ">プレイリスト楽曲追加</a><br>
  <a href="/api/spotify/remove_track_from_playlist?q=しわあわせ">プレイリスト楽曲削除</a>'
end

get '/api/spotify/search' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].search(params[:q]).to_json
end

get '/api/spotify/playlists' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].get_playlists.to_json
end

get '/api/spotify/playlist' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].get_playlist(request['music_api'].get_playlists.first[:id]).to_json
end

get '/api/spotify/playlist/tracks' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].get_playlist_tracks(request['music_api'].get_playlists.first[:id]).to_json
end

get '/api/spotify/create_playlist' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].create_playlist(params[:name]).to_json
end

get '/api/spotify/add_track_to_playlist' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].add_track_to_playlist(request['music_api'].get_playlists.first[:id], request['music_api'].search(params[:q]).first[:id]).to_json
end

get '/api/spotify/remove_track_from_playlist' do
  redirect '/' unless session[:spotify_token]
  content_type :json
  request['music_api'].remove_track_from_playlist(request['music_api'].get_playlists.first[:id], request['music_api'].search(params[:q]).first[:id]).to_json
end

get '/api/spotify/callback' do
  token = Music::SpotifyApi.get_token_by_code(params['code'], SPOTIFY_REDIRECT_URL)
  session[:spotify_token] = token['access_token']
  redirect '/menu/spotify'
end
