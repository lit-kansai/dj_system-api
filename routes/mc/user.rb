require_relative './user/link'
require_relative './user/playlist'

class McUserRouter < Base
  before do
    halt unauthorized unless @env["user"]
  end

  # ユーザー(管理者&MC)情報取得
  get "/" do
    send_json(is_admin: @env["user"].is_admin)
  end

  # ユーザー(管理者&MC)情報更新
  put "/" do
    @env["user"].update(is_admin: params[:is_admin])
    internal_server_error("Failed to save") unless @env["user"].save
    send_json(is_admin: @env["user"].is_admin)
  end

  # ユーザー(管理者&MC)情報削除
  delete "/" do
    @env["user"].delete
    session.clear
    send_json(ok: true)
  end

  bind_router "/link", McUserLinkRouter
  bind_router "/playlist", McUserPlaylistRouter
end
