module Music
  class SpotifyApi < ApiInterface
    class << self
      def get_redirect_url(client_id, client_secret, redirect_uri)
        "http://example.com/redirect_url"
      end

      def build(code, redirect_uri)
        access_token = "XXX"
        return self.new(access_token)
      end
    end
  end
end