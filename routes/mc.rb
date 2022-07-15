require_relative './mc/auth'
require_relative './mc/room'
require_relative './mc/user'

class McRouter < Base
  bind_router "/auth", McAuthRouter
  bind_router "/room", McRoomRouter
  bind_router "/user", McUserRouter
end
