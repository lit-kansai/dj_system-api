require 'base64'

module MusicApi
  class AppleMusicApi < ApiInterface
    API_ENDPOINT = 'https://api.music.apple.com/v1/'
    @@client_access_token=nil

    def initialize(access_token, music_user_token)
      @access_token = access_token
      @music_user_token = music_user_token
      @apple_music_api = Faraday.new(:url => API_ENDPOINT)
      @apple_music_api.headers['Authorization'] = "Bearer #{access_token}"
      @apple_music_api.headers['Content-Type'] = 'application/json'
      @apple_music_api.headers['Accept-Language'] = 'ja'
      @apple_music_api.headers['Media-User-Token'] = music_user_token
    end

    # 検索
    def search(query)
      res = @apple_music_api.get "catalog/jp/search" , { types: 'songs', term: query }
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.get 'catalog/jp/search', { types: 'songs', term: query }
      end
      return nil unless res.status >= 200 && res.status < 300
      body = JSON.parse(res.body)
      body["results"]["songs"]["data"].map { |track|
        {
          id: track['id'],
          artists: track['attributes']['artistName'],
          album: track['attributes']['albumName'],
          thumbnail: track['attributes']['artwork']['url'].to_s.gsub(/({w}|{h})/, '3000'),
          name: track['attributes']['name'],
          duration: (track['attributes']['durationInMillis'] / 1000).ceil,
        }
      }
    end

    # trackの取得
    def get_track(track_id)
      res = @apple_music_api.get "catalog/jp/songs/#{track_id}"
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.get "catalog/jp/songs/#{track_id}"
      end
      return nil unless res.status >= 200 && res.status < 300
      res = JSON.parse(res.body)
      track = res["data"][0]
      {
        id: track['id'],
        artists: track['attributes']['artistName'],
        album: track['attributes']['albumName'],
        thumbnail: track['attributes']['artwork']['url'].to_s.gsub(/({w}|{h})/, '3000'),
        name: track['attributes']['name'],
        duration: (track['attributes']['durationInMillis'] / 1000).ceil,
      }
    end

    # プレイリスト一覧
    def get_playlists()
      res = @apple_music_api.get 'me/library/playlists?extend'
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.get 'me/library/playlists?extend'
      end
      return nil unless res.status >= 200 && res.status < 300
      body = JSON.parse(res.body)
      body["data"].map { |data|
        image_url = data['attributes']['artwork']['url'].to_s.gsub(/({w}|{h})/, '3000') if data['attributes']['artwork'] != nil
        description = data['attributes']['description']['standard'] if data['attributes']['description'] != nil
        {
          id: data['id'],
          name: data['attributes']['name'],
          description: description,
          image_url: image_url,
          provider: 'applemusic'
        }
      }
    end

    # プレイリストの取得
    def get_playlist(playlist_id)
      res = @apple_music_api.get "me/library/playlists/#{playlist_id}"
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.get "me/library/playlists/#{playlist_id}"
      end
      return nil unless res.status >= 200 && res.status < 300
      body = JSON.parse(res.body)
      body["data"].map { |data|
        image_url = data['attributes']['artwork']['url'].to_s.gsub(/({w}|{h})/, '3000') if body['data'][0]['attributes']['artwork'] != nil
        {
          id: data['id'],
          name: data['attributes']['name'],
          description: data['attributes']['description']['standard'],
          image_url: image_url,
          provider: 'applemusic'
        }
      }
    end

    # プレイリストの取得(id指定)
    def get_playlist_tracks(playlist_id)
      res = @apple_music_api.get "me/library/playlists/#{playlist_id}/tracks"
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.get "me/library/playlists/#{playlist_id}/tracks"
      end
      body = JSON.parse(res.body)
      return [] unless res.status >= 200 && res.status < 300
      body['data'].map { |item|
        {
          id: item['attributes']['playParams']['catalogId'],
          artists: item['attributes']['artistName'],
          album: item['attributes']['albumName'],
          thumbnail: item['attributes']['artwork']['url'].to_s.gsub(/({w}|{h})/, '3000'),
          name: item['attributes']['name'],
          duration: (item['attributes']['durationInMillis'] / 1000).ceil,
        }
      }
    end

    #人気曲の取得
    def get_top_music(playlist_id,limit_tracks)
      res = @apple_music_api.get "catalog/jp/playlists/#{playlist_id}/tracks?limit=#{limit_tracks}"
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.get "catalog/jp/playlists/#{playlist_id}/tracks?limit=#{limit_tracks}"
      end
      body = JSON.parse(res.body)
      return nil unless res.status >= 200 && res.status < 300
      body['data'].map { |item|
        {
          id: item['id'],
          artists: item['attributes']['artistName'],
          album: item['attributes']['albumName'],
          thumbnail: item['attributes']['artwork']['url'].to_s.gsub(/({w}|{h})/, '3000'),
          name: item['attributes']['name'],
          duration: (item['attributes']['durationInMillis'] / 1000).ceil,
        }
      }
    end

    # プレイリストの作成
    def create_playlist(name, description)
      data = {
        attributes: {
          name: name,
          description: description ? description + " - Generated by DJ Gassi" : "Generated by DJ Gassi",
        }
      }
      res = @apple_music_api.post "me/library/playlists", JSON.generate(data)
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.post "me/library/playlists", JSON.generate(data)
      end
      return nil unless res.status >= 200 && res.status < 300
      body = JSON.parse(res.body)
    end

    # playlistへtrackの追加
    def add_track_to_playlist(playlist_id, track_id)
      data = {
        data: [
          {
            id: track_id,
            type: "songs"
          }
        ]
      }
      playlist_tracks = get_playlist_tracks(playlist_id)
      unless playlist_tracks.all? {|t| t[:id] != track_id }
        return nil
      end
      res = @apple_music_api.post "me/library/playlists/#{playlist_id}/tracks", JSON.generate(data)
      if res.status == 401
        regenerate_access_token
        res = @apple_music_api.post "me/library/playlists/#{playlist_id}/tracks", JSON.generate(data)
      end
      return nil unless res.status >= 200 && res.status < 300
      # No response body
    end

    def regenerate_access_token()
      secret = ENV['APPLE_MUSIC_API_PRIVATE_KEY']
      keyId = ENV['APPLE_MUSIC_API_KEY_ID']
      teamId = ENV['APPLE_MUSIC_API_TEAM_ID']

      hours_to_live = 24
      algorithm = 'ES256'

      time_now = Time.now.to_i
      time_expired = Time.now.to_i + hours_to_live * 3600

      payload = {
        'iss': teamId,
        'iat': time_now,
        'exp': time_expired,
      }

      ecdsa_key = OpenSSL::PKey::EC.new(secret)
      @access_token = JWT.encode payload, ecdsa_key, algorithm, header_fields = {kid: keyId, type: 'JWT'}
      @apple_music_api.headers['Authorization'] = "Bearer #{@access_token}"
    end

    # クラスメソッドの定義
    class << self
      def generate_access_token()
        secret = ENV['APPLE_MUSIC_API_PRIVATE_KEY']
        keyId = ENV['APPLE_MUSIC_API_KEY_ID']
        teamId = ENV['APPLE_MUSIC_API_TEAM_ID']

        hours_to_live = 24
        algorithm = 'ES256'

        time_now = Time.now.to_i
        time_expired = Time.now.to_i + hours_to_live * 3600

        payload = {
          'iss': teamId,
          'iat': time_now,
          'exp': time_expired,
        }

        ecdsa_key = OpenSSL::PKey::EC.new(secret)
        @@client_access_token = JWT.encode payload, ecdsa_key, algorithm, header_fields = {kid: keyId, type: 'JWT'}
      end

      def search(search_keyword)
        if @@client_access_token.nil?||@@client_access_token===""
          generate_access_token()
        end
        http1=Faraday.new(url: API_ENDPOINT)
        res = http1.get  do |req|
          req.params[:q] = search_keyword
          req.params[:type] = 'track'
          req.url 'search'
          req.headers['Content-Type'] = "application/json"
          req.headers['Authorization'] = "Bearer #{@@client_access_token}"
          req.headers['Media-User-Token'] = @music_user_token
        end
        return JSON.parse(res.body)
      end
    end
  end
end
