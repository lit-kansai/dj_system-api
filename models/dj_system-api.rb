ActiveRecord::Base.establish_connection
class User < ActiveRecord::Base
    has_many :RoomUsers
    has_many :Rooms, through: :RoomUsers
    has_many :Rooms
    has_many :AccessTokens
end

class RoomUser < ActiveRecord::Base
    belongs_to :User
    belongs_to :Room
end

class AccessToken < ActiveRecord::Base
    belongs_to :User
end

class Room < ActiveRecord::Base
    has_many :RoomUsers
    has_many :Users, through: :RoomUsers
    has_many :Letters
    belongs_to :User
end

class Letter < ActiveRecord::Base
    belongs_to :Room
    has_many :Songs
end

class Song < ActiveRecord::Base
    belongs_to :Letter
end