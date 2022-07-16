class Google
  SCOPES = ['https://www.googleapis.com/auth/userinfo.profile']
  API_ENDPOINT = 'https://www.googleapis.com/oauth2/v1/'

  def initialize(access_token, refresh_token)
    @access_token = access_token
    @refresh_token = refresh_token

    @google_api = Faraday.new(:url => API_ENDPOINT)
    @google_api.headers['Authorization'] = "Bearer #{access_token}"
    @google_api.headers['Content-Type'] = 'application/json'
  end

  def profile()
    res = @google_api.get 'userinfo'
    body = JSON.parse(res.body)
  end

  class << self
    def get_oauth_url(redirect_uri)
      query = {
        response_type: 'code',
        client_id: ENV['GOOGLE_API_CLIENT_ID'],
        scope: SCOPES.join(' '),
        redirect_uri: redirect_uri,
        state: SecureRandom.hex(16)
      }

      'https://accounts.google.com/o/oauth2/auth?' + query.to_param
    end

    def get_token_by_code(code, redirect_uri)
      if code === nil || code === ""
        raise ArgumentError, "invalid code"
      end

      params = {
        code: code,
        redirect_uri: redirect_uri,
        grant_type: 'authorization_code'
      }

      res = Faraday.new.post do |req|
        req.headers["Authorization"] = 'Basic ' + Base64.strict_encode64(ENV['GOOGLE_API_CLIENT_ID'] + ':' + ENV['GOOGLE_API_CLIENT_SECRET'])
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.url 'https://accounts.google.com/o/oauth2/token'
        req.body = params.to_query
      end

      return JSON.parse(res.body)
    end
  end
end
