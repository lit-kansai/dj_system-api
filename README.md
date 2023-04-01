<div align="center">
<img alt="DJ-Gassi_logo2" height="300" src="https://user-images.githubusercontent.com/57238213/229261614-2f85aa48-650d-48c8-808d-ee8990cfcb0b.png"><br />
</div>

# DJ System Front

DJ SystemのAPIです。

## Quick Start

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
CORS_DOMAINS=
```
