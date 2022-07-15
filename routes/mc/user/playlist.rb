class McUserPlaylistRouter < Base
  # ユーザーのプレイリスト一覧
  get "/" do
    list = []
    @env["user"].access_tokens.each do |access_token|
      case access_token.provider
      when 'spotify'
        return forbidden("provider is not linked") unless @env["spotify"]
        list.concat(@env["spotify"].get_playlists)
      end
    end
    send_json list
  end

  # ユーザーのプレイリスト一覧（プロバイダ別）
  get "/:provier" do
    case params[:provier]
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
      send_json @env["spotify"].get_playlists
    else
      return bad_request("unsupported provider")
    end
  end

  # プレイリストの楽曲一覧
  get "/:provier/:playlist_id" do
    case params[:provier]
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
      res = @env["spotify"].get_playlist_tracks(params[:playlist_id])
      return not_found_error("playlist not found") unless res
      return send_json res
    else
      return bad_request("unsupported provider")
    end
  end

  # プレイリスト作成
  post "/:provier" do
    return bad_request("invalid parameters") unless has_params?(params, [:name])
    case params[:provier]
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
      res = @env["spotify"].create_playlist(params[:name], params[:description])
      return send_json(ok: true, id: res['id'])
    else
      return bad_request("unsupported provider")
    end
  end
end
