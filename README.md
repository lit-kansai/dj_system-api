<div align="center">
<img alt="DJ-Gassi_logo2" height="300" src="https://github.com/lit-kansai/dj_system-api/assets/61298948/9035e2e5-1f76-4d48-84e6-56282a3d45f7"><br />
</div>

# DJ System API

DJ System の API です。

## Quick Start

必ず`rackup`コマンドを使用してください。

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
APPLE_MUSIC_API_PRIVATE_KEY=
APPLE_MUSIC_API_KEY_ID=
APPLE_MUSIC_API_TEAM_ID=
```

## 技術

| 目的           | 技術          | 備考                                                                                                                                                                      |
| -------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 言語           | Ruby          |                                                                                                                                                                           |
| フレームワーク | Sinatra       | 規模が大きいので[modular style](https://sinatrarb.com/intro.html#:~:text=Sinatra%3A%3ABase%20%2D%20Middleware%2C%20Libraries%2C%20and%20Modular%20Apps)を採用しています。 |
| ORM            | Active Record |                                                                                                                                                                           |
| サーバ         | AWS EC2       |                                                                                                                                                                           |

## 特殊な実装について

### base.rb

Sinatra の modular style は通常`Sinatra::Base`もしくは`Sinatra::Application`を継承したクラスを作成しますが、このプロジェクトでは `Sinatra::Base`を継承して新たに`Base`クラスを作り、こちらを使用しています。

これにより、全てのルートで共通な関数を定義したり、設定をすることが出来ます。

また、`Base`クラスの中でもかなり特殊な（ある意味 Evil とも捉えられる）実装である`bind_router`メソッドについては次のセクションで解説しています。

### bind_router メソッドについて

このメソッドを理解するためには 2 つの前提を理解する必要があります。まず 1 つ目に`Sinatra::Base`クラスが Rack に準拠しており、`call`メソッドを呼び出すことで Rack アプリケーションとして動作するようになっている事を知っておく必要があります。

そして、Rack アプリケーションとは、環境を引数として受け取り、status / header / body を返すメソッド「call」が定義されているクラスということになります。

つまるところ、`Sinatra::Base`クラスはこの Rack アプリケーションの仕様に基づき、`get`メソッドや`post`メソッドの定義を元にルーティングを処理し、その結果を Rack の形式に変換して返すという仕組みになっているということです。

---

2 つ目に、Ruby ではクラスの直下でメソッドを呼び出せるという仕様を知る必要があります。

この仕様については[こちらの記事](https://dev.classmethod.jp/articles/ruby-under-class-method-timing/)が参考になりますが、クラス直下に書いたメソッドはクラスが読み込まれたタイミングで呼び出されるという仕様になっています。

そして、実は`get '/' do`のような`get`や`post`はこちらの仕組みが使われており、クラス直下で`get`メソッドを呼び出しているということになります。

また、`get`メソッドも Call メソッドと互換があるので、`get`メソッドの引数に Rack アプリケーションを渡すことが出来ます。

---

これらを整理して、別のファイルを元に`get`や`post`メソッドを呼び出せばいいのでは？と考えたのがこの`bind_router`です。

`bind_router`を呼び出すと、任意のパス配下の処理を別のクラスに委譲することが出来ます。また、@変数は維持されるので、`bind_router`を呼び出す前に定義した変数をそのまま使うことが出来ます。

Sinatra が一部`@env["PATH_INFO"]`を元に処理している部分があるため、ここだけ予め変更するように Proc を記述しています。

Sinatra は条件によっては上から優先して処理をしていく場合があるので、`bind_router`は必ずクラス末尾に記述する必要があります。
