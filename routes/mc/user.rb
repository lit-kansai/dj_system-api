require_relative './user/link'
require_relative './user/playlist'

class McUserRouter < Base
  before do
    halt unauthorized unless @env["user"]
  end

  # ユーザー(管理者&MC)情報取得
  get "/" do
    google_user = @env["google"].profile
    send_json(
      name: google_user["name"],
      icon: google_user["picture"],
      is_admin: @env["user"].is_admin,
      linked_providers: @env["user"].access_tokens.where.not(provider: "google").pluck(:provider)
    )
  end

  # ユーザー(管理者&MC)情報削除
  delete "/" do
    @env["user"].delete
    send_json(ok: true)
  end

  bind_router "/link", McUserLinkRouter
  bind_router "/playlist", McUserPlaylistRouter
end
