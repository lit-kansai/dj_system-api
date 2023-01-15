class McAuthRouter < Base
  # Googleアカウントでログイン
  get "/signin" do
    return bad_request("invalid parameters") unless has_params?(params, [:redirect_url])
    send_json(redirect_url: Google.get_oauth_url(params['redirect_url']))
  end

  # Google OAuth後に呼び出すAPI
  post "/signin/callback" do
    return bad_request("invalid parameters") unless has_params?(params, [:code, :redirect_url])

    google_token = Google.get_token_by_code(params['code'], params['redirect_url'])
    return bad_request("invalid code or redirect_url") unless google_token['access_token']

    google_id = Google.new(google_token['access_token'], google_token['refresh_token']).profile['id']
    return internal_server_error unless google_id

    user = User.find_or_create_by(google_id: google_id)
    user.access_tokens.find_or_create_by(provider: 'google').update(access_token: google_token['access_token'], refresh_token: google_token['refresh_token'])
    token = JWT.encode({ user_id: user.id, exp: Time.now.to_i + 604800 }, ENV['JWT_SECRET'], 'HS256')
    
    cookies[:api_token] = token
    send_json(api_token: token, user_id: user.id)
  end
end
