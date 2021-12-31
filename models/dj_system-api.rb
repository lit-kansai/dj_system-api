ActiveRecord::Base.establish_connection
class User < ActiveRecord::Base
    has_many :room_users
    has_many :rooms,through: :room_users
    has_many :my_rooms,class_name:"rooms",foreign_key:"id"
    has_many :access_tokens
end

class RoomUser < ActiveRecord::Base
    belongs_to :user
    belongs_to :room
end

class AccessToken < ActiveRecord::Base
    belongs_to :user
end

class Room < ActiveRecord::Base
    has_many :room_users
    has_many :users, through: :room_users
    has_many :letters
    belongs_to :user
end

class Letter < ActiveRecord::Base
    belongs_to :room
    has_many :songs
end

class Song < ActiveRecord::Base
    belongs_to :letter
end