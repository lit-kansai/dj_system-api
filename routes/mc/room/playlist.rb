class McRoomPlaylistRouter < Base
  # ルームプレイリスト - 楽曲一覧
  get "/" do
    case @env["room"].provider
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
      res = @env["spotify"].get_playlist_tracks(@env["room"].playlist_id)
      return not_found_error("playlist not found") unless res
      send_json res
    when 'applemusic'
      return forbidden("provider is not linked") unless @env["applemusic"]
      res = @env["applemusic"].get_playlist_tracks(@env["room"].playlist_id)
      return not_found_error("playlist not found") unless res
      send_json res
    else
      return not_found_error("playlist not found")
    end
  end

  # ルームプレイリスト - 楽曲追加
  post "/music" do
    return bad_request("invalid parameters") unless has_params?(params, [:music_id])

    case @env["room"].provider
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
      res = @env["spotify"].add_track_to_playlist(@env["room"].playlist_id, params[:music_id])
      return not_found_error unless res
      send_json(ok: true)
    when 'applemusic'
      return forbidden("provider is not linked") unless @env["applemusic"]
      @env["applemusic"].add_track_to_playlist(@env["room"].playlist_id, params[:music_id])
      send_json(ok: true)
    else
      return not_found_error("playlist not found")
    end
  end

  # ルームプレイリスト - 楽曲削除
  delete "/music" do
    # DELETEはbodyがparamsに入らないため、bodyを取得している
    body = JSON.parse(request.body.read)
    return bad_request("invalid parameters") unless has_params?(body, ["music_id"])

    case @env["room"].provider
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
      res = @env["spotify"].remove_track_from_playlist(@env["room"].playlist_id, body["music_id"])
      return not_found_error unless res
      send_json(ok: true)
    else
      return not_found_error("playlist not found")
    end
  end
end
