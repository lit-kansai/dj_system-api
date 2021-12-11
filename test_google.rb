require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
Dotenv.load

require "./lib/google.rb"

enable :sessions

GOOGLE_REDIRECT_URL = "http://localhost:4567/api/google/callback"

before do
  request['google_api'] = Google.new(session[:google_token]) if session[:google_token]
end

get '/' do
  "<a href=\"#{Google.get_oauth_url(GOOGLE_REDIRECT_URL)}\">Googleログイン</a>"
end

# Google

get '/menu/google' do
  redirect '/' unless session[:google_token]
  '<a href="/api/google/profile">プロフィール取得</a>'
end

get '/api/google/profile' do
  redirect '/' unless session[:google_token]
  content_type :json
  request['google_api'].profile.to_json
end

get '/api/google/callback' do
  token = Google.get_token_by_code(params['code'], 'test', GOOGLE_REDIRECT_URL)
  session[:google_token] = token['access_token']
  puts token
  redirect '/menu/google'
end
