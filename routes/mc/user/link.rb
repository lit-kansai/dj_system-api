class McUserLinkRouter < Base
  # Spotifyとの連携
  get "/spotify" do
    return bad_request("invalid parameters") unless has_params?(params, [:redirect_url])
    send_json(redirect_url: MusicApi::SpotifyApi.get_oauth_url(params['redirect_url']))
  end

  # Spotify後に呼び出すAPI
  post "/spotify/callback" do
    return bad_request("invalid parameters") unless has_params?(params, [:code, :redirect_url])

    spotify_token = MusicApi::SpotifyApi.get_token_by_code(params['code'], params['redirect_url'])
    return internal_server_error("failed to get token") unless spotify_token['access_token']

    @env["user"].access_tokens.find_or_create_by(provider: 'spotify').update(access_token: spotify_token['access_token'], refresh_token: spotify_token['refresh_token'])
    send_json(ok: true)
  end
end
