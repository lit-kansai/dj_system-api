DJ SYSTEM API
===

DJ Gassi用API

## 開発環境構築

```
$ git clone https://github.com/lit-kansai/dj_system-api
$ cd dj_system-api
$ bundle install
$ rake db:create
$ rake db:migrate
$ $EDITOR .env
$ rackup config.ru
```

### 環境変数

```
SPOTIFY_API_CLIENT_ID=
SPOTIFY_API_CLIENT_SECRET=
GOOGLE_API_CLIENT_ID=
GOOGLE_API_CLIENT_SECRET=
JWT_SECRET=
```
