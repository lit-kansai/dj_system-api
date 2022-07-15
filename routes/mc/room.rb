require_relative './room/playlist'

class McRoomRouter < Base
  before do
    halt unauthorized unless @env["user"]
  end

  # ルームIDが必要なURIの場合 @env["room"] にルーム情報を入れる
  before "/:room_id*" do
    if params[:room_id]
      if @env["user"]
        @env["room"] = @env["user"].rooms.find_by(display_id: params[:room_id])
      else
        @env["room"] = Room.find_by(display_id: params[:room_id])
      end
      halt not_found_error("Room not found") if @env["room"].nil?
    end
  end

  # room個別情報
  get "/:room_id" do
    send_json @env["room"].as_json(include: [:users, :letters])
  end

  # room作成
  post "/" do
    return bad_request("invalid parameters") unless has_params?(params, [:url_name, :room_name, :description])

    provider = nil
    playlist_id = nil

    # プレイリストの指定がある場合
    if has_params?(params, [:provider, :playlist_id])
      case params[:provider]
      when 'spotify'
        return forbidden("provider is not linked") unless @env["spotify"]
        provider = params[:provider]
        res = @env["spotify"].get_playlist(params[:playlist_id])
        return not_found_error("playlist not found") unless res
        playlist_id = params[:playlist_id]
      end
    elsif has_params?(params, [:provider])
      case params[:provider]
      when 'spotify'
        return forbidden("provider is not linked") unless @env["spotify"]
        provider = params[:provider]
        res = @env["spotify"].create_playlist(params[:room_name], params[:description])
        playlist_id = res['id']
      end
    end

    @env["room"] = @env["user"].my_rooms.build(
      users: [@env["user"]],
      display_id: params[:url_name],
      name: params[:room_name],
      description: params[:description],
      provider: provider,
      playlist_id: playlist_id
    )
    return internal_server_error("Failed to save") unless @env["room"].save

    send_json @env["room"]
  end

  # 全room情報取得(管理可能なroomのみ)
  get "/" do
    send_json @env["user"].rooms.as_json(include: [:users])
  end

  # room個別情報更新
  put "/:room_id" do
    @env["room"].display_id = params[:url_name] if params.has_key?(:url_name)
    @env["room"].name = params[:room_name] if params.has_key?(:room_name)
    @env["room"].description = params[:description] if params.has_key?(:description)
    return bad_request("Failed to save") unless @env["room"].save

    send_json @env["room"].as_json(include: [:users])
  end

  # room個別削除
  delete "/:room_id" do
    @env["room"].destroy
    send_json(ok: true)
  end

  # room内お便り取得
  get "/:room_id/letters" do
    
  end

  # room内楽曲取得
  get "/:room_id/musics" do
    
  end
end