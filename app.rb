require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

Dotenv.load
 
get '/' do
    "Hello World!"
end