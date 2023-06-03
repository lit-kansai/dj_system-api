class McUserLinkRouter < Base
  # Spotifyとの連携
  get "/spotify" do
    return bad_request("invalid parameters") unless has_params?(params, [:redirect_url])
    send_json(redirect_url: MusicApi::SpotifyApi.get_oauth_url(params['redirect_url']))
  end

  #Spotifyの連携解除
  delete "/spotify"do
    @env["user"].access_tokens.find_or_create_by(provider: 'spotify').user.rooms.each do |room|
      room.destroy
    end
    @env["user"].access_tokens.find_or_create_by(provider: 'spotify').destroy
    send_json(ok: true)
  end

  # Spotify後に呼び出すAPI
  post "/spotify/callback" do
    return bad_request("invalid parameters") unless has_params?(params, [:code, :redirect_url])

    spotify_token = MusicApi::SpotifyApi.get_token_by_code(params['code'], params['redirect_url'])
    return internal_server_error("failed to get token") unless spotify_token['access_token']

    @env["user"].access_tokens.find_or_create_by(provider: 'spotify').update(access_token: spotify_token['access_token'], refresh_token: spotify_token['refresh_token'])
    send_json(ok: true)
  end

  # Apple Musicとの連携
  get "/applemusic" do
    access_token = MusicApi::AppleMusicApi.generate_access_token()
    send_json(access_token: access_token)
  end

  # Apple Music連携後のリダイレクト先
  post "/applemusic/callback" do
    return bad_request("invalid parameters") unless has_params?(params, [:access_token, :music_user_token])
    @env["user"].access_tokens.find_or_create_by(provider: 'applemusic').update(access_token: params['access_token'], music_user_token: params['music_user_token'])
    send_json(ok: true)
  end
end
