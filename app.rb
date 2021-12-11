require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require "./lib/music/music.rb"
require "./lib/google.rb"

Dotenv.load
 
get '/' do
    "Hello World!"
end