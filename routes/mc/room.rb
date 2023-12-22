require_relative './room/playlist'

SUPPORTED_PROVIDERS = ['spotify', 'applemusic']

class McRoomRouter < Base
  before do
    # room内のプレイリスト取得を認証しない
    if request.path_info.split("/")[-1] == 'musics'
      return
    else
      halt unauthorized unless @env["user"]
    end
  end

  # ルームIDが必要なURIの場合 @env["room"] にルーム情報を入れる
  before "/:room_id*" do
    if @env["user"]
      @env["room"] = @env["user"].rooms.find_by(display_id: params[:room_id])
    # room内のプレイリスト取得時は、DBからroom_idによりroomを取得する
    elsif request.path_info.split("/")[-1] == 'musics'
      @env["room"] = Room.find_by(display_id: params[:room_id])
    end
    halt not_found_error("Room not found") if @env["room"].nil?
  end

  # room個別情報
  get "/:room_id" do
    send_json @env["room"].as_json(include: [:users, musics: { include: [:letter] }, letters: { include: [:musics] }])
  end

  # room作成
  post "/" do
    return bad_request("invalid parameters") unless has_params?(params, [:provider, :url_name, :room_name, :description])

    provider = params[:provider]
    playlist_id = nil

    case params[:provider]
    when 'spotify'
      return forbidden("provider is not linked") unless @env["spotify"]
    when 'applemusic'
      return forbidden("provider is not linked") unless @env["applemusic"]
    else
      return forbidden("provider is not linked")
    end

    if Room.exists?(display_id: params[:url_name])
      return bad_request("url_name is already used")
    end

    # プレイリストの指定がある場合
    if has_params?(params, [:playlist_id])
      case params[:provider]
      when 'spotify'
        res = @env["spotify"].get_playlist(params[:playlist_id])
        return not_found_error("playlist not found") unless res
        playlist_id = params[:playlist_id]
      when 'applemusic'
        res = @env["applemusic"].get_playlist(params[:playlist_id])
        return not_found_error("playlist not found") unless res
        playlist_id = params[:playlist_id]
      end
    else
      case params[:provider]
      when 'spotify'
        res = @env["spotify"].create_playlist(params[:room_name], params[:description])
        playlist_id = res['id']
      when 'applemusic'
        res = @env["applemusic"].create_playlist(params[:room_name], params[:description])
        playlist_id = res['data'][0]['id']
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
    providers = @env["user"].access_tokens.where.not(provider: "google")
    valid_provider = []
    SUPPORTED_PROVIDERS.each do |provider|
      if !(providers.find_by(provider: provider).nil?)
        valid_provider.push(provider)
      end
    end
    send_json @env["user"].rooms.where(provider: valid_provider).as_json()
  end

  # room個別情報更新
  put "/:room_id" do
    if Room.exists?(display_id: params[:url_name]) && @env["room"].display_id != params[:url_name]
      return bad_request("url_name is already used")
    end

    @env["room"].display_id = params[:url_name] if params.has_key?(:url_name)
    @env["room"].name = params[:room_name] if params.has_key?(:room_name)
    @env["room"].description = params[:description] if params.has_key?(:description)
    @env["room"].room_cooltime = params[:room_cooltime] if params.has_key?(:room_cooltime)
    return internal_server_error("Failed to save") unless @env["room"].save

    send_json @env["room"].as_json()
  end

  # room個別削除
  delete "/:room_id" do
    @env["room"].destroy
    send_json(ok: true)
  end

  # room内お便り取得
  get "/:room_id/letters" do
    @letters = @env["room"].letters.as_json(include: [:musics])
    send_json @letters
  end

  # room内楽曲取得
  get "/:room_id/musics" do
    @musics = @env["room"].musics.order(created_at: "DESC").as_json(include: [:letter])
    send_json @musics
  end

  # room内お便り削除
  delete "/:room_id/letter/:letter_id" do
    @letter = @env["room"].letters.order(created_at: "DESC").find_by(id: params[:letter_id])
    return not_found_error("letter not found") if @letter.nil?
    @letter.destroy
    send_json ok: true
  end

  # room内楽曲削除
  delete "/:room_id/music/:music_id" do
    @music = @env["room"].musics.find_by(id: params[:music_id])
    return not_found_error("music not found") if @music.nil?
    @music.destroy
    send_json ok: true
  end

  bind_router "/:room_id/playlist", McRoomPlaylistRouter
end
