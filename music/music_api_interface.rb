module Music
  class ApiInterface
    attr_accessor :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    # 楽曲を検索
    def search(query)
      raise NotImplementedError
    end

    # プレイリスト一覧を取得
    def playlists()
      raise NotImplementedError
    end

    # プレイリストの楽曲一覧を取得
    def get_playlist_tracks(playlist_id)
      raise NotImplementedError
    end

    # プレイリストを作成
    def create_playlist(name)
      raise NotImplementedError
    end

    # 楽曲をプレイリストに追加
    def add_track_to_playlist(playlist_id, track_id)
      raise NotImplementedError
    end

    # 楽曲をプレイリストから削除
    def remove_track_from_playlist(playlist_id, track_id)
      raise NotImplementedError
    end

    # クラスメソッド
    class << self
      # リダイレクトURLを返す
      def get_redirect_url(client_id, client_secret, redirect_uri)
        raise NotImplementedError
      end

      # codeを元にtokenを取得
      def get_token_by_code(code, state, redirect_uri)
        raise NotImplementedError
      end
    end
  end
end