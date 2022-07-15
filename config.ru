require 'bundler/setup'
Bundler.require
Dotenv.load

require './app'
DjSystemApi.run!
