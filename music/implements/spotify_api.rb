require 'base64'

module Music
  class SpotifyApi < ApiInterface
    SCOPES = ['playlist-read-private', 'playlist-read-collaborative', 'playlist-modify-public', 'playlist-modify-private']

    def initialize(access_token)
    end


    class << self
      def get_redirect_url(client_id, client_secret, redirect_uri)
        query = {
          response_type: 'code',
          client_id: ENV['SPOTIFY_API_CLIENT_ID'],
          scope: SCOPES.join(' '),
          redirect_uri: redirect_uri,
          state: SecureRandom.hex(16)
        }
        
        'https://accounts.spotify.com/authorize?' + query.to_param
      end

      def build(code, state, redirect_uri)
        if code === nil || code === ""
          raise ArgumentError, "invalid code"
        end

        if state === nil || state === ""
          raise ArgumentError, "invalid state"
        end

        params = {
          code: code,
          redirect_uri: redirect_uri,
          grant_type: 'authorization_code'
        }

        res = Faraday.new.post do |req|
          req.headers["Authorization"] = 'Basic ' + Base64.strict_encode64(ENV['SPOTIFY_API_CLIENT_ID'] + ':' + ENV['SPOTIFY_API_CLIENT_SECRET'])
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.url 'https://accounts.spotify.com/api/token'
          req.body = params.to_query
        end

        return self.new(JSON.parse(res.body)['access_token'])
      end
    end
  end
end