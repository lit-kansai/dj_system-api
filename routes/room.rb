class RoomRouter < Base
  # ルームIDが必要なURIの場合 @env["room"] にルーム情報を入れる
  before "/:room_id*" do
    @env["room"] = Room.find_by(display_id: params[:room_id])
    halt not_found_error("Room not found") if @env["room"].nil?
  end

  # ルーム情報取得
  get "/:room_id" do
    room = Room.find_by(display_id: params[:room_id])
    return not_found_error unless room
    
    send_json id: room["display_id"], name: room["name"], description: room["description"]
  end

  # 楽曲検索
  get "/:room_id/music/search" do
    room = Room.find_by(display_id: params[:room_id])
    return not_found_error unless room
    
    case room.provider
    when 'spotify'
      search_name = params[:q]
      token = room.master.access_tokens.find_by(provider: 'spotify')
      return forbidden("provider is not linked") unless token
      spotify = MusicApi::SpotifyApi.new(token.access_token, token.refresh_token)
      music_list = spotify.search(search_name)
      send_json music_list
    else
      forbidden("provider is not linked")
    end
  end

  # リクエスト送信
  post "/:room_id/request" do
    return bad_request("invalid parameters") unless has_params?(params, [:musics])

    room = Room.find_by(display_id: params[:room_id])
    return not_found_error unless room

    letter = room.letters.build(
      radio_name: params[:radio_name] || "",
      message: params[:message] || "",
    )

    return internal_server_error("Failed to save") unless letter.save

    params[:musics].each do |music|
      token = room.master.access_tokens.find_by(provider: room.provider)
      next unless token

      case room.provider
      when 'spotify'
        spotify = MusicApi::SpotifyApi.new(token.access_token, token.refresh_token)
        track = spotify.get_track(music)
        next unless track

        letter.musics.build(
          provided_music_id: track['id'],
          name: track['name'],
          artist: track['artists'],
          album: track['album'],
          thumbnail: track['thumbnail'],
          duration: track['duration'],
        )
        spotify.add_track_to_playlist(room.playlist_id, music)
      else
        forbidden("provider is not linked")
      end
    end

    send_json(ok: true)
  end
end
