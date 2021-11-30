require 'dotenv'
require 'oauth2'
require 'active_support'
require 'active_support/core_ext'
require 'faraday'

Dotenv.load

require "./music/music.rb"

SPOTIFY_CLIENT_ID = ENV["SPOTIFY_CLIENT_ID"]
SPOTIFY_CLIENT_SECRET = ENV["SPOTIFY_CLIENT_SECRET"]
REDIRECT_URL = "http://localhost:4567/api/spotify/callback"

url = Music::SpotifyApi.get_redirect_url(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, REDIRECT_URL)

puts "下記のURLにブラウザでアクセスしてください"
puts url
puts
puts "認証が完了したら、URLのクエリにあるcodeを入力してください: "

code = gets.chomp

music = Music::SpotifyApi.build(code, 'test', REDIRECT_URL)
puts music.access_token

# music.search("シュガーハイウェイ")
