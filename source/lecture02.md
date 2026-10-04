---
var:
  header-title: "2026-4I データベース工学 第02回 講義資料"
  header-date: "2026年10月07日 (木) 1時限"
---

# 第02回 4I-データベース工学

## 連絡と概要

- 小テスト❶ を実施します。筆記用具を用意しておいてください。
  - 遅刻・欠席等により追試験を希望する場合は [前回講義で案内した手続き](lecture01.html#成績評価法と履修上の注意) をしてください。
- 今回の講義は「**Docker関連の環境構築**」がメインとなってきます。

## 前回講義の振返りと確認

前回講義では「**なぜデータベース (DBMS) を使ったデータ管理が必要なのか**」を学びました。また、リレーショナルデータベースの特長や機能を簡単に紹介し、[DB Fiddle](https://www.db-fiddle.com/) というサービスを使って SQL による RDB の操作を体験してもらいました。

また、最後に [Docker Desktop](https://www.docker.com/ja-jp/products/docker-desktop/) を PC にインストールしてもらいました。そして、動作確認として [DockerHub](https://hub.docker.com/) から `hello-world` という Docker コンテナのイメージを**プル**して (＝取得して)、そのイメージをもとにコンテナを作成・起動して、Docker が正常に動作するかを確認してもらいました。

- [DockerHub](https://hub.docker.com/) とは、公式およびユーザが作成した Docker イメージを公開・共有できる **公式リポジトリ (格納庫)** です。
  - PostgreSQL をはじめとする各種 DBMS のイメージのほか、Python・C++・Java・Go・Haskell・OCaml などの **プログラミング言語の実行環境や開発環境のイメージ**、Apache や nginx、**WordPress**、**LaTeX** などのイメージ、さらに **Supabase** などの複合的な開発プラットフォーム向けイメージ群など、様々なイメージが提供されています。
- Docker では、イメージ (Image) を雛形として、コンテナ (Container) を作成します。これは、オブジェクト指向プログラミングにおいて <span class="masked">「クラス」から「インスタンス」を生成する関係</span> に例えることができます。

また、宿題 (＝今回の講義に向けた準備) として、以下のコマンドを用いて `postgres:18.6` と `dbgate/dbgate:7.2.6` という Docker イメージをプル (取得) をしてもらいました。

```
docker image pull postgres:18.6
docker image pull dbgate/dbgate:7.2.6
```

今回の講義は、以上の作業が完了していることを前提とします。

::: {.note .type-tips}
**そもそも Docker とは何か？**

3年の「知能情報実験実習1」の後期テーマのなかで、既に Docker を使用して **Apacheコンテナ** (ウェブサーバ) を動かしているので、概要は把握しているハズですが...

Docker とは、**アプリを動かすための環境を OS (Linux)ごと<sup>※</sup> ひとまとめにした「イメージ」から、すぐに使える軽量な実行環境「コンテナ」を作成して、動かすことができるソフトウェア**です。コンテナはそれぞれ独立して動作するため、ホスト OS の環境 (レジストリなど) を汚すことなく、様々な開発環境を安全に試すことができるメリットがあります。

※ ここでの「OS」とは、Linux カーネルを除いたユーザー空間 (ライブラリやコマンド群など) を指します。
::: 


## Docker 上での PostgreSQL コンテナの起動と操作
 
Docker を使って PostgreSQL (RDBMS) のコンテナを作成・起動し、実際に使ってみます。一般に「Dockerコンテナ」の **<u>基本的なライフサイクル</u>** は、次のようになります。

1. Docker Hub から イメージを取得する
    - `docker image pull` コマンド
2. イメージからコンテナを作成する (必要に応じてカスタマイズ) 
    - `docker container create` コマンド
3. コンテナを起動する⤴
    - `docker container start` コマンド
4. コンテナを利用する 
    - `docker container exec` コマンド
      - TCP/IP (ポート通信) によるアプリ接続
5. コンテナを停止する⤵
    - `docker container stop` コマンド
    - 必要に応じて **3.** に戻る🔙
6. コンテナを削除する 
    - `docker container rm` コマンド
7. イメージを削除する（不要になった場合）
    - `docker image rm`

::: {.balloon .char-01 .face-05 .tone-red}
以降に掲載するスクリーンショットは、以前のバージョンで作成したものを含みます。

**画面中のバージョン表記については、以下のように読み替えてください**。

- postgres:**17.6** 👉 postgres:**18.6**
- dbgate/dbgate:**6.6.3** 👉 dbgate/dbgate:**7.2.6**
:::


### 準備

はじめに Docker Desktop が起動済みで、ステータスが「**Running**」となっていることを確認してください。タスクトレイにアイコンが見つからない場合はスタートメニューから「Docker Desktop」を探して手動で起動してください。

![img](figs/01/docker-01.png)

次に [PostgreSQL v18.6](https://hub.docker.com/_/postgres) と [DbGate v7.2.6](https://hub.docker.com/r/dbgate/dbgate) のイメージがプルできていること (ローカルにダウンロードできていること) を確認します。

ターミナルから次のコマンドを使って、ローカルに存在する **Docker イメージの一覧 (リスト)** を確認してください。

```powershell
docker images
```

コマンドの応答に、次のようなものが含まれていれば問題なくイメージのプルができています。

```
IMAGE                  ID
postgres:18.6          662db3da228c  
dbgate/dbgate:7.2.6    95a402f3cb33  
hello-world:latest     e2ac70e7319a
```

::: {.balloon .char-01 .face-04 .tone-blue}
Docker Desktop (Docker Engine) が**立ち上がっていないとき**は、以下のようなエラーが返ってきます。

```
failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine; check if the path is correct and if the daemon is running: open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.
```
:::

Dockerイメージの一覧は、**Docker Desktop (GUI)** からも確認できます。

![img](figs/02/docker-desktop-03.png) 


<!-- 要更新 -->

::: {.note .type-tips}
**Dockerイメージ「postgres:18.6」の構成**

皆さんには宿題として `postgres:18.6` というDockerイメージをプルしてもらいました。`postgres:17.6` は **Debian 13** (コードネーム Trixie／トリクシー) の軽量版 (`debian:trixie-slim`) の上で **PostgreSQL 18.6** が動作するように構成された Docker イメージとなります。
:::


::: {.balloon .char-01 .face-05 .tone-blue}
Debian (デビアン) は Linux を代表するディストリビューションのひとつで、各リリースには <span class="masked">映画「トイ・ストーリー」</span> に登場するキャラクタ名がコードネームとして採用されています。

- 参考: [Debian のバージョン履歴](http://ja.wikipedia.org/wiki/Debianのバージョン履歴) @ Wikipedia
:::

### コンテナの作成

Docker イメージ `postgres:18.6` をもとに、PostgreSQL のユーザ名やパスワードなどを環境変数として指定して、**pg18** という名前をつけた Docker コンテナ を作成していきます。

- 「イメージ」は、「コンテナ」を作成するための **雛形（テンプレート）** と考えてください。

次の `docker container create` コマンドを実行してください。

```
docker container create --name pg18 -e POSTGRES_USER=student -e POSTGRES_PASSWORD=secret123 -e POSTGRES_DB=playground postgres:18.6
```

正常に作成されると、Docker から「**コンテナID**」が返されます。


::: {.balloon .char-01 .face-02 .tone-yellow}
コンテナIDは、Docker が各コンテナを識別するために自動的に割り当てる「64文字の16進数の識別子」です。コンテナごとに異なるIDが割り当てられるため、<u>皆さんの画面に表示される値は講義資料の例とは異なります</u>。

なお、`docker container ls` などでは、この64文字すべてではなく、**通常は先頭部分だけを使った短縮IDが表示**されます。
:::


::: {.note .type-tips}
**コマンドを複数行に分けて書くときのルール**


長いコマンドは <span class="masked">シェルごとに決められた記号</span> を使って複数行に分けて記述できます。

PowerShell では「**行末**」に **バッククォート** `` ` `` を用いることでコマンドを複数行に分けて入力できます。同様のことを **Bash** で行なう場合は**バックスラッシュ** `\`、**コマンドプロンプト** (cmd.exe) で行なう場合は**キャレット** (**ハット**) `^` を使用します。

```
docker container create --name pg18 `
  -e POSTGRES_USER=student `
  -e POSTGRES_PASSWORD=secret123 `
  -e POSTGRES_DB=playground `
  postgres:18.6
```

**PowerShell** の場合、複数行のコマンドを貼り付けようとすると、以下のようなダイアログが表示されます。内容を確認して「**強制的に貼り付け**」を選択してください。

![img](figs/02/ps-01.png)

:::

ここで、`docker container create` コマンドで指定している各オプションの意味は次の通りです。

- **--name pg18**
  - コンテナに `pg18` という名前をつけけています。コンテナ名には、英数字、ハイフン `-`、アンダーバー `_`、ピリオド `.` などを使用できます。ただし、先頭文字は英数字にする必要があります。
- **-e POSTGRES_USER=student**
  - **環境変数** `POSTGRES_USER` に `student` という値を設定します。
  - PostgreSQL の公式 Docker イメージでは、この環境変数の値をもとに、初期化時に <span class="masked">`student` という名前のスーパーユーザ（＝管理ユーザ）が自動作成</span> されます。
- **-e POSTGRES_PASSWORD=secret123**
  - **環境変数** `POSTGRES_PASSWORD` に `secret123` という値を設定します。
  - これにより、上記で作成されるスーパーユーザ `student` のパスワードとして `secret123` が設定されます。
- **-e POSTGRES_DB=playground**
  - 環境変数 `POSTGRES_DB` に `playground` という値を設定します。
  - これにより、初期化時に <span class="masked">`playground` という名前のデータベースが自動作成</span> されます。
- **postgres:18.6**
  - コンテナの雛形として使用する **Docker イメージの名前とタグ (バージョン) **を指定します。

このように、Docker イメージの多くは、**環境変数を指定することで、コンテナを最初に起動するときの初期化処理をカスタマイズ**できるようになっています。利用できる環境変数やその役割は、Docker Hub 上の各イメージの詳細ページなどに記載されています。

- PostgreSQLの公式イメージの「**How to extend this image**」は [こちら](https://hub.docker.com/_/postgres#https://hub.docker.com/_/postgres#how-to-extend-this-image) (カスタマイズ用の環境変数の設定などが記載されています)。

なお、PostgreSQL の公式 Docker イメージでは、これらの初期化処理は <u>**PostgreSQL のデータを保存する領域がまだ初期化されていない場合にのみ実行**</u> されます。

::: {.balloon .char-01 .face-05 .tone-blue}
環境変数の指定だけでは対応できないような、**パッケージの追加**や設定ファイルの変更、アプリケーションに必要なファイルの組み込みなどを行いたい場合は、`Dockerfile` というファイルを使用します。

`Dockerfile` は、既存の Docker イメージをもとにして「**このパッケージを追加する**」「**この設定を適用する**」といった処理を順番に記述し、**自分でカスタマイズした Docker イメージを作成するための設計図のようなもの** となります。

`Dockerfile` の役割や書き方、そこから新しい Docker イメージを作成する方法については、後で詳しく解説します。
:::

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例** <font size="-1">(意味や理解が曖昧な事項は生成AIを使って、再確認しておきましょう)</font>

> OS の「環境変数」とは何ですか。

> Linux における「スーパーユーザ」とは何ですか。

> Docker において「Dockerfile」とは何をするものですか。コンテナの作成に必須ですか。

::: {.note .type-tips}
**コンテナの削除**

既に同名のコンテナ (`pg17`) が存在するときに、`docker container create ...` を実行すると次のようなエラーが返ってきます。

```
Error response from daemon: Conflict. The container name "/pg17" is already in use by container "xxxx". You have to remove (or rename) that container to be able to reuse that name.
```

このときは、**次のコマンドで「既存のコンテナ」を先に削除してから**、再度、`docker container create ...` コマンドを実行してください。`rm` は、remove の略です。

```
docker container rm pg17
```

なお、起動中のコンテナを削除する際には `-f` オプションをつけてください (停止中のコンテナの削除に対しては `-f` オプション不要です)。
:::

#### 定着確認

- Docker では、「コンテナ」を雛形として「イメージ」を作成する。この説明は「適切である」か「適切ではない」か答えよ。
  - **答え**: <span class="masked">適切ではない</span>
- `hoge:3.14` という Docker イメージから、`hoge-fuga` というコンテナを作成するためのコマンド (作成するだけで起動はしない) を答えよ。
  - **答え**: <span class="masked">`docker container create --name hoge-fuga hoge:3.14`</span> もしくは <span class="masked">`docker create --name hoge-fuga hoge:3.14`</span> という省略形も可 (本科目では非推奨)。
- `hoge:3.14` という Docker イメージを Docker Hub からプルするコマンドを答えよ。
  - **答え**: <span class="masked">`docker image pull hoge:3.14`</span> もしくは <span class="masked">`docker pull hoge:3.14`</span> という省略形も可 (本科目では非推奨)。
- `hoge-fuga` という Docker コンテナ (停止中) を削除するためのコマンドを答えよ。
  - **答え**: <span class="masked">`docker container rm hoge-fuga`</span> もしくは <span class="masked">`docker rm hoge-fuga`</span> という省略形も可 (本科目では非推奨)
- Docker コンテナの「名前」に使うことができる文字を答えよ。
  - **答え**: <span class="masked">半角の英小文字・数字・ハイフン</span>

### コンテナの状態確認

存在している**コンテナの一覧 (リスト)** は、次のコマンドで確認できます。`ps` とは <span class="masked">process status (プロセスの状態)</span> の略です。`--all` (Long Option) は、`-a` (Short Option) とすることもできます。

```
docker ps --all
```

コマンドを実行すると、次のような応答が返ってくるはずです。**IMAGE** が `postgres:17.6`、**NAMES** が `pg17` (コンテナの作成時に `--name` で指定した名前)、**STATUS** が `Created` となっている行が存在することを確認してください。 

```
CONTAINER ID   IMAGE           COMMAND            CREATED         STATUS    PORTS     NAMES
d2196c5352d3   postgres:17.6   "docker-entry…"    2 seconds ago   Created             pg17
```

なお、(停止中のコンテナは除外して) **起動中のコンテナだけ**を表示したい場合は `--all` のオプションを外して次のようにしてください。

```
docker ps
```

現時点では `pg17` というコンテナを作成しただけで、まだ「**コンテナの起動はしていない状態**」なのでリストには何も表示されないはずです (別途、Claude の MCP などで、コンテナを起動しているときは、それが表示されることがあります)。

#### 定着確認

- Docker で起動中のコンテナだけの一覧を表示するコマンドを答えよ。
  - **答え**: <span class="masked">`docker ps`</span>
- Docker で停止中のものを含めてコンテナの一覧を表示するコマンドを答えよ。
  - **答え**: <span  class="masked">`docker ps -a`もしくは`docker ps --all`</span>

### コンテナの起動

コンテナを起動するときは、次のように **コンテナの名前** (例えば `pg17`) を指定して `docker container start` コマンドを実行します。

```
docker container start pg17
```

成功すると「コンテナ名」が応答として返ってきます。

コンテナが起動したことを確認するために `docker ps` コマンドを実行し、`pg17` コンテナの **STATUS** が <span class="masked">「Up」</span> になっていることを確認してください。

なお、Dockerコンテナの状況 (一覧・起動・停止) は、**Docker Desktop (GUI)** からも確認することができます。起動中のコンテナは、**Name** の項目の前に緑色の <font color="#2c7b70">●</font> マークがついて、**Actions** の項目が 停止マーク <font color="#1d63ed"><i class="fa-solid fa-stop"></i></font> になります。

![img](figs/02/docker-desktop-01.png)


#### 定着確認

- `hoge:3.14` という Docker イメージから `hoge-fuga` というコンテナが作成済みのとき、そのコンテナを起動するためのコマンドを答えよ。
  - **答え**: <span class="masked">`docker container start hoge-fuga`</span> もしくは <span class="masked">`docker start hoge-fuga`</span> という省略形も可 (本科目では非推奨)。

### コンテナの利用 (Bash経由)

ここまでの操作で `pg17` というコンテナが起動し、そこで <span class="masked">PostgreSQL 17 (RDBMS) が起動している状態</span> となりました。実際にこれを使用していきたいと思います。

まずは、次の `docker container exec` コマンドで、コンテナの内部 (Linux) に **ログイン** していきます。

```
docker container exec -it pg17 bash
```

- 上記コマンドは `docker exec -it pg17 bash` のように `container` を省略することも可能です。

`docker container exec` は、既に起動しているコンテナのなかで <span class="masked">任意のコマンドを実行 (execute) する</span> ためのコマンドとなります。付加している `-it` オプションは、**対話的 (Interactive) にターミナルをつなぐためのオプション** となります。

このコマンドを実行すると、**コンテナのなかの Linux (Debian) に接続し、そのシェル環境 (Bash) で対話的にコマンドを実行できる状態** になります。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> `docker container exec` コマンドで指定する `-it` オプションについて詳しく解説してください。

> Linuxの操作に関する文脈において「シェル」とは何ですか。

> Linuxの操作に関する文脈において「bash」とは何ですか。

#### Linuxシェル (Bash) の操作

上記のように `docker container exec -it pg17 bash` コマンドを実行すると、**ターミナルのプロンプト** (＝コンソールに関する文脈では <span class="masked">ユーザに入力を促すために表示される文字列</span> を意味する) が、次のように切り替わります。

```
root@d2196c5352d3:/#
```

- 対象のコンテナが起動していないときは `Error response from daemon: container xxxx is not running` のようなエラーとなります。
- 対象のコンテナが存在しないときは `Error response from daemon: No such container: pg17` のようなエラーとなります。

このようにプロンプトが変わったことで、操作対象が「**Windows の PowerShell**」から「**Docker コンテナ内の Linux のBash環境**」に**切り替わっていること**が確認できます。

::: {.note .type-tips}

**ターミナルに表示されるプロンプトが持つ情報**

Linux の `root@d2196c5352d3:/#` というプロンプトには、次のような情報が含まれています。

- `root`: **ログインしているユーザ名**を表しています。「root」は <span class="masked">管理者 (スーパーユーザ)</span> を意味します。
- `@d2196c5352d3`: **ホスト名** を表しています。このホスト名は「docker ps」コマンドで確認できるコンテナIDと一致するはずです。
- `:/`: コロンの右側は **カレントディレクトリ (カレントフォルダ) の位置** を表しています。いまは「/」なので、**ルートディレクトリ** がカレントディレクトリであることを表しています。
- `#`: 管理者 (スーパーユーザ) であることを表しています。一般ユーザのときは `$` が表示されます。
:::

PostgreSQL コンテナ (`pg17`) の内部が「**どのような Linux 環境で構成されているか**」は、次のコマンドで確認することができます。

```
cat /etc/os-release
```

上記のコマンドを実行すると、以下のように Debian 13 (コードネーム **trixie** ) に関する情報が表示されます。

```
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.1
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

なお、このコンテナでは `ls` や `pwd`、`cd` などの基本コマンドは使えますが、`nano` や `vim`、`vi` といった**エディタは入っていません**。そのため、コンテナ内部の設定ファイルを編集したい場合などは、別の方法を使う必要があります。

#### psql の対話モードで PostgreSQL を操作

このコンテナでは、既に「**PostgreSQL のサーバープロセス**」が起動しており、[RDBMSのクライアントツール](lecture01.html#リレーショナルデータベース-rdb)から接続して利用できる状態になっています。サーバの稼働状態は `pg_isready` コマンドから確認できます。

では、実際に PostgreSQL の公式 CLI クライアントツールである `psql` を使って接続していきます。次のコマンドを実行してください。CLI: Command Line Interface

```
psql -U student -d playground
```

ここで `-U` は <span class="masked">ログインする「ユーザ名」</span>、`-d` は <span class="masked">接続する「データベース名」</span> を指定するためのオプションとなります。

コマンドを実行すると「**PostgreSQL の対話モード**」が開始し、ターミナルのプロンプトが以下のような表示 (`接続しているデータベース名=#`) になります。これにより、SQL を打ち込んで、データベースを操作する準備が整いました。

```
psql (17.6 (Debian 17.6-2.pgdg13+1))
Type "help" for help.

playground=#
```

対話モードの利用中に、SQLを入力・実行しても「**反応がない？**」と感じたときは、セミコロン `;` を入力して Enter キーを入力してみてください。反応がないように見えるとき、たいていは、システムがコマンド終端の `;` を待っている状態です。それでも解決しなときは、ターミナルを閉じて、再度、`docker container exec ...` で接続してください。

#### テーブルの作成 (CREATE TABLE)

動作確認として、次に示す `s_users` というテーブルを作成してみます (`s` はサンプルという意味でつけています)。RDBMSの「テーブル名」は、前回も説明したように一般的には <span class="masked">複数形で命名してスネークケース</span> で記述します (ただし、チームやプロジェクトの規約が優先)。

**■ s_users **

| id | name  | age |
|:--:|:------|:---:|
|  1 | Alice | 20  |
|  2 | Bob   | 25  |

まずは、**テーブルのスキーマ** (＝<span class="masked">列構成やデータ型の設計情報</span>) を指定して**テーブルを作成する SQL **を実行します。以下を、コピーして、ターミナルに貼りけて実行してみてください。

```sql{.numberLines caption="テーブルを作成するSQL"}
CREATE TABLE s_users (id INT PRIMARY KEY, name TEXT NOT NULL, age INT);
```

成功すると `CREATE TABLE` のように表示されます。もし **同名のテーブルが既に存在している場合** は `ERROR:  relation "s_users" already exists` のようなエラーになります。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL を使用しています。`CREATE TABLE s_users (id INT PRIMARY KEY, name TEXT NOT NULL, age INT);` という SQL について詳細に解説してください。

#### レコードの挿入 (INSERT)

次に、**レコードを挿入する SQL** を実行します。成功すると `INSERT 0 2` と表示されます。

```sql{.numberLines caption="2件のレコードを挿入するSQL"}
INSERT INTO
  s_users (id, name, age)
VALUES
  (1, 'Alice', 20),
  (2, 'Bob', 25);
```

SQL では <span class="masked">改行</span> を無視するので `INSERT INTO s_users (id, name, age) VALUES (1, 'Alice', 20), (2, 'Bob', 25);` のように1行で与えても問題ありません。 

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL で、テーブルに2件のレコードを挿入したら `INSERT 0 2` のように表示されました。`0` と `2` の意味について解説してください。

::: {.note .type-tips}

**テーブルから全てのレコードを削除したいときは...**

指定したテーブルから全てのレコードを削除する場合は `DELETE FROM` を使用します。

```sql{.numberLines caption="すべてのレコードを削除するSQL (1)"}
DELETE FROM s_users;
```

また、`TRUNCATE TABLE` を使用すると、より高速に全件削除ができます。**IDシーケンス**についてもリセットされます。

```sql{.numberLines caption="すべてのレコードを削除するSQL (2)"}
TRUNCATE TABLE s_users;
```

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> リレーショナルデータベースにおける `DELETE FROM xxx` と `TRUNCATE TABLE xxxx` の違いについて教えてください。

> リレーショナルデータベースにおける「IDシーケンス」とは何ですか。

:::

::: {.note .type-tips}
**テーブルそのものを削除したいときは...**

レコードを含めてテーブルそのものを削除する場合は `DROP TABLE` を使用します。

```sql{.numberLines caption="テーブルを削除するSQL"}
DROP TABLE s_users;
```
:::

#### レコードの抽出 (SELECT)

次に、レコード全件を **抽出 (選択) する SQL** を実行します。

```sql{.numberLines caption="全件の全列のレコードを抽出するSQL"}
SELECT * FROM s_users;
```

実行結果は、次のようになります。

```
 id | name  | age
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
(2 rows)
```

---

次のように、**列 (カラム) の出力順を指定して抽出すること** もできます。

```sql{.numberLines caption="列を明示して全列のレコードを抽出するSQL"}
SELECT age, id, name FROM s_users;
```

実行結果は、次のようになります。

```
 age | id | name
-----+----+-------
  20 |  1 | Alice
  25 |  2 | Bob
(2 rows)
```

また、`SELECT name, age FROM s_users;` とすれば、`name` と `age` だけを抽出・表示することができます (`id` の列は抽出・表示しない)。

#### PosgreSQL の対話モードの終了 と Linuxシェルの終了

**psql** で `\q` (もしくは`[Ctrl]+[D]`のショートカット) を入力すると対話モードが終了して、Linux のシェルに戻ります。

- ターミナルのプロンプトは `root@d2196c5352d3:/#` のようになるはずです。

さらに、`exit` (もしくは`[Ctrl]+[D]`のショートカット) を入力するとLinux のシェルが終了して、Windows のPowerShell に戻ってきます。

- ターミナルのプロンプトは `PS C:\Users\xxxx>` のようになるはずです。

### コンテナの利用 (Windows から psql を直接実行)

上記の手順では <span class="masked">いったんコンテナのなかに入ってから、シェル経由で psql を実行</span> していました。しかし、**Windows側からコンテナの psql コマンドを直接叩くことも可能** です。

例えば、次のような SQL を記述した `hoge.sql` というファイルをWindows側で用意しておきます。

```sql{.numberLines caption="hoge.sql"}
SELECT * FROM s_users;
```

このSQLファイルを、次のように **ファイルリダイレクト** (`<`) を使って **psql** に流し込むことができます。ここでは、オプションを `-it` ではなく `-i` にしている点に注意してください。 

```
docker container exec -i pg17 psql -U student -d playground < hoge.sql
```

**_注意_**: 上記コマンドは **PowerShell ではなくコマンドプロンプト (cmd.exe)** から実行してください。PowerShell ではファイルリダイレクト (`<`) が利用できません。

実行結果は、次のようになります。宿題として授業時間外で試してみてください。

![img](figs/02/cmd-01.png)

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Docker に関する質問です。`docker container exec -it pg17 bash` では `-it` オプションなのに、`docker container exec -i pg17 psql -U student -d playground < hoge.sql` では `-i` オプションにするのはなぜですか。

> Linuxなどのシェルに関する文脈において「ファイルリダイレクト」とは何ですか？

### コンテナの停止

次のコマンドで `pg17` のコンテナを停止 (≠削除) します。

```
docker container stop pg17
```

念のために `docker ps` で起動中のコンテナ一覧に `pg17` が含まれていないことを確認してください。

#### 演習

再び `pg17` コンテナを起動し、そこに接続し `psql` から `SELECT * FROM s_users;` を実行し、**テーブルのデータが残っていること** (＝<span class="masked">コンテナを停止してもデータが消失しないこと</span>) を確認してください。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Docker で `docker create --name pg17 -e POSTGRES_USER=hoge -e POSTGRES_PASSWORD=fuga -e POSTGRES_DB=piyo postgres:17.6` のようにコンテナを作成しました。  
> このコンテナを起動して、データベースにテーブルを作成して、レコードを挿入しました。その後、このコンテナを停止し、再度、起動すると、テーブルとレコードの情報が消えずに残っていました。これらの情報は、どこに保存されていたのでしょうか。

### コンテナの削除

次のコマンドで `pg17` のコンテナを削除します。コンテナを削除すると、データベースの内容 (例えば、先ほど作成した `s_users` など) も一緒に削除されます。

```
docker container rm pg17
```

念のために `docker ps -a` (`-a` は停止中のコンテナも含めて表示するオプション) で、`pg17` が消えていることを確認してください。

停止中のものも含めて、コンテナが1個も存在しないとき、Docker Desktop では以下のような表示となります。

![img](figs/02/docker-desktop-02.png)

#### 演習

ここまでの一連の操作 (コンテナの作成👉コンテナの起動👉コンテナの利用 (psqlからSQLの実行)👉コンテナの停止👉コンテナの削除) を、再度、実行して Docker に関する基本的なコマンド操作に慣れてください。

- 授業時間外学習を利用して、3回目、4回目も実行して理解を深めるとともにコマンドに慣れてください。

::: {.note .type-senior}

**イメージのプル、コンテナの作成・起動をまとめて実行するコマンド**

ここまでは「イメージのプル」「コンテナの作成」「コンテナの起動」を個別に実行しましたが、`docker container run` コマンドでは、**これらの3つをまとめて実行すること** ができます。

```
docker container run --name pg17 `
  -e POSTGRES_USER=student `
  -e POSTGRES_PASSWORD=secret123 `
  -e POSTGRES_DB=playground `
  -d `
  postgres:17.6
```

`-d` オプションによって、コンテナを **デタッチドモード** (Detached Mode) で起動します。これにより、コンテナは **バックグラウンドで実行** され、ターミナルはすぐに操作可能な状態に戻ります。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Docker の `docker container run` コマンドにおいて「コンテナをデタッチモードで起動する」とは、どういうことですか？デタッチモードで起動しないときの動作はどうなりますか。

なお、`run` は、`pull` `create` `start` をまとめて実行するものなので、以降は `stop` で停止、再び起動するときは `start` を使用します。既に同名のコンテナが存在する場合は `run` は失敗するので注意してください。

:::

### まとめ

以上のように Docker を利用することで、**即座に利用可能な PostgreSQL 環境が簡単に構築・破棄できる**ようになります。Windows に直接 PostgreSQL をインストール/アンインストールする場合と比較し、**大幅に手間と時間を省くこと**ができます。

- 参考: [WindowsネイティブにPostgreSQLをインストールする手順](https://qiita.com/tom-sato/items/037b8f8cb4b326710f71#インストーラのダウンロード)

#### 定着確認

- ターミナルのプロンプトが `root@d2196c5352d3:/#` のように表示されているとき、その操作対象は「Windows の PowerShell」「Docker コンテナ内の Linux シェル」「PostgreSQL の対話モード (psql)」のうち、どれと考えることができるか。
  - **答え**: <span class="masked">Docker コンテナ内の Linux シェル</span>
- `docker ps` コマンドによって表示されるのは「停止中のコンテナのみ」と「起動中のコンテナのみ」のどちらか答えよ。
  - **答え**: <span class="masked">起動中のコンテナのみ</span>
- 起動中の Docker コンテナ `pg17` を削除するには、まずコンテナを停止したうえで削除する必要がある。
そのための一連のコマンドを答えよ。
  - **答え**: <span class="masked">`docker container stop pg17`、`docker container rm pg17`</span>
- RDB において `s_users` というテーブルのレコードを全件抽出するSQLを答えよ。
  - **答え**: <span class="masked">`SELECT * FROM s_users;`</span>
- RDB において `s_users` というテーブルのレコードを全件削除するSQLを答えよ。
  - **答え**: <span class="masked">`DELETE FROM s_users;`</span> もしくは <span class="masked">`TRUNCATE TABLE s_users;`</span> 
- RDB において `s_users` というテーブルそのものを削除するSQLを答えよ。
  - **答え**: <span class="masked">`DROP TABLE s_users;`</span>

## Docker Desktop による Docker の GUI 操作

ここまでは CLI (CUI) ベースの Docker 操作について紹介してきましたが、これらの操作は **Docker Desktop** を利用して GUI から行なうこともできます。

### コンテナの起動

`docker container start xxxx` コマンド相当の操作

![img](figs/02/docker-desktop-04.png)

### コンテナの停止

`docker container stop xxxx` コマンド相当の操作

![img](figs/02/docker-desktop-05.png)

### コンテナのシェルを利用

`docker container exec -it xxxx bash` コマンド相当の操作

![img](figs/02/docker-desktop-07.png)

**Exec** タブを選択します。

![img](figs/02/docker-desktop-08.png)

### コンテナの削除

`docker container rm xxxx` コマンド相当の操作

![img](figs/02/docker-desktop-06.png)

## Docker 環境での PostgreSQL のポート通信設定

ここまでの説明では `docker container exec` を使って、コンテナ内の **psql** (クライアントツール) から PostgreSQL のサーバプロセスを利用しました。**psql** は `psql -U student -d playground` のように起動したとき、<span class="masked">UNIXドメインソケット</span> というものを介して、PostgreSQL のサーバプロセスと通信をします。

**UNIXドメインソケット** とは、Linux や macOS のようなUNIX系OSで使われるプロセス間通信 (IPC: Inter-Process Communication) の仕組みで、**同じホスト上で動作するプログラム同士が、ネットワークを経由せずに高速に直接データをやり取りするための方法** です。

つまり、ここまでの範囲で説明した使い方は、「PostgreSQL のサーバプロセス」と「クライアントツール」の通信が <span class="masked">すべて「コンテナの内部」で完結しているもの</span> でした。

一方で、PostgreSQL のサーバプロセスとは別のホストのクライアントツールから接続するとき、**TypeScript や Python などのプログラムからDB接続するとき** には <span class="masked">TCP/P 接続 (ポート通信)</span> を使う必要があります。

Docker Desktop を起動している「Windows (ホストOS)」と「Docker コンテナ」の間での TCP/IP 接続を有効化するには `docker container create ` コマンドの実行時に、次のように `-p` オプションを指定する必要があります。

```
docker container create --name pg17 `
  -e POSTGRES_USER=student `
  -e POSTGRES_PASSWORD=secret123 `
  -e POSTGRES_DB=playground `
  -p 5432:5432 `
  postgres:17.6
```

この設定により、

- PostgreSQLのサーバプロセスが稼働しているコンテナの5432番ポート と
- ホストOS (Windows) の5432番ポート が

マッピングされるようになります。これで、任意のクライアントツールやプログラムから 5432番ポートを使って PostgreSQL に接続できるようになります。

なお、既にホストOS側で別のアプリで 5432 番ポートを使っている場合は `-p 5432:5433` のようにして、ホスト側のポート番号を 5433 に変えることができます。

#### 定着確認

- PostgreSQL をはじめとする代表的な RDBMS で使用される標準の通信ポート番号を答えよ。
  - **答え**: <span class="masked">5432番</span>
- Linux や macOS などの UNIX 系 OS において、同一ホスト内のプロセス間通信に使われ、PostgreSQL のローカル接続にも利用される仕組みを何というか答えよ。
  - **答え**: <span class="masked">UNIXドメインソケット</span>

### 演習 (宿題・授業時間外)

TCP/IP ポートのマッピング設定を含めて Docker コンテナを作成・起動し、Windows (ホストOS) 上のクライアントツールから、コンテナ内の PostgreSQL サーバプロセスに接続してみましょう。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Dockerコンテナとホストで「ポートをマッピングをする」とは、どのようなことですか。PostgreSQL のコンテナを作成する状況を想定して解説してください。

#### コンテナ側の準備

まず、`pg17` という名前のコンテナが存在していれば `docker container rm pg17` コマンドで削除しておきます。

次に、以下の `docker container run` コマンドで、**5432番ポート (RDBMSの標準ポート) のマッピング設定** を含めてコンテナを作成・起動します。

```
docker container run --name pg17 `
  -e POSTGRES_USER=student `
  -e POSTGRES_PASSWORD=secret123 `
  -e POSTGRES_DB=playground `
  -p 5432:5432 `
  -d `
  postgres:17.6
```

つづいて `docker container exec -it pg17 bash` コマンドで、`pg17` コンテナにログインし、**psql** で `s_users` テーブルを作成し、いくつかのレコードを挿入しておきます ([参考1](#テーブルの作成-create-table)、[参考2](#コンテナのシェルを利用))。

::: {.note .type-tips}

**ホストとコンテナのポート対応の確認**

作成済みコンテナにおいて、どのポートがどのようにマッピングされているか (＝ホスト👉コンテナの対応) を確認するためには `docker port` コマンドを使用します。

`docker port pg17` のようにコマンドを実行すると、次のような結果が表示されます。

```
5432/tcp -> 0.0.0.0:5432
5432/tcp -> [::]:5432
```

**1行目** は、コンテナ内の TCP ポート `5432` が、ホストOSの **IPv4 アドレス** `0.0.0.0` の `5432` 番ポートに公開されていること、を示しています。ここでの `0.0.0.0` は「すべての IPv4 アドレスで受け付ける」という特別な指定で、実際には `127.0.0.1` (ローカルホスト) などのすべての IPv4 経路を含みます。

- たとえば、ホストマシンの IP アドレスが `192.168.1.8` の場合、`192.168.1.8:5432`、`127.0.0.1:5432`、`localhost:5432` など、いずれの経路からアクセスしてもコンテナ内のポート `5432` に転送されることを意味します。

**2行目**は **IPv6*+ 向けの設定で、同様に IPv6 のすべてのアドレス (`[::]`) で接続を受け付けていることを示しています。

:::

#### ホスト側の準備とTCP/IP接続

次に、PostgreSQLに対応し、インストール不要で使える軽量のSQLクライアント「**HeidiSQL** (ハイディエスキューエル)」を取得してきます。[こちら](https://www.heidisql.com/download.php)から「**Portable Windows version (zipped)**」をダウンロードしてきます。

![img](figs/02/heidi-sql-01.png)

ダウンロードした Zipファイル を **完全展開** して、`heidisql.exe` をダブルクリックして起動してください (Zipのプレビューモードでは `heidisql.exe` は正常実行されないので注意してください)。

HeidiSQL の起動後、新規の**DB接続設定**を作成するために、画面左下の「**新規**」ボタンを押下します。

![img](figs/02/heidi-sql-02.png)

次のように接続設定をします。**ユーザ**、**パスワード**、**データベース** の各項目は `docker container run` コマンドで環境変数に設定した値を入力してください。入力が完了したら「**開く**」ボタンを押下します。

![img](figs/02/heidi-sql-03.png)

設定を保存するかを確認されるので「**はい**」を選択してください。

![img](figs/02/heidi-sql-04.png)

ここまでの手順にミスがなければ、5432番ポートを介して、コンテナで起動している PostgreSQL のサーバプロセスに接続され、以下のような画面が開きます。

画面上の `public` を展開して `s_users` テーブルを選択してください。

![img](figs/02/heidi-sql-05.png)

さらに、以下のように「**データ**」タブを選択することで、テーブルのレコードを確認することができます。

![img](figs/02/heidi-sql-06.png)

「**クエリ**」タブを選択し、SQLを実行することもできます。

![img](figs/02/heidi-sql-07.png)

以上のように、コンテナを作成する際にポートのマッピングを設定することで、コンテナの外部から TCP/IP 通信で PostgreSQL に接続することができます。

なお、これ以降、本授業で **HeidiSQL** を使用する予定はないので、ダウンロードしたZipと、展開したフォルダは削除してもらって構いません。

## Docker とは (詳細)

以上のハンズオンを通じて、体験的に Docker の概要が把握できたと思います。ここからは、Docker について、少しだけ詳しく解説していきたいと思います。

---

[Docker](https://ja.wikipedia.org/wiki/Docker)とは「**コンテナ型仮想化技術**」を実装したソフトウェアで、これを利用することで <span class="masked">普段使いのPC環境をクリーンに保ったまま、様々な開発環境を構築</span> できるようになります。しかも、**それぞれの開発環境が相互に影響しないようにすること** ができるようになります。

- 例えば、**プロジェクトA** のために、Python のバージョンを `3.10` から `3.13` に上げたら、「プロジェクトB で開発中だったアプリが動かなくなった💦」といったトラブルを回避することができるようになります。

Docker を利用すると「**なにがうれしいのか**🤔」について、具体的な状況を想定して詳しく考えてみたいと思います。例として、次のような状況を考えていきます。

>「データベース工学」の授業で「PostgreSQL 17」の環境構築が必要で、同時に「応用専門PBL2」でのプロジェクト開発で「PostgreSQL 15」の環境構築が必要になった。

このようなとき、次のような問題が考えられます。

- PostgreSQL は、異なるバージョンを同時にインストール可能なものの、ポート番号やデータディレクトリの管理が煩雑になり、設定ミスのリスクが高くなる。
  - 異なるバージョンの同時インストールが不可のプログラミング言語やサービスも存在
- 短期間の限定的な利用のために PostgreSQL という重量級の常駐型ミドルウェアをインストールすることに抵抗感がある。
  - 様々な開発環境のインストールとアンインストールを繰り返すと、レジストリが肥大化していきます。その結果、OSの起動に時間がかかったり、動作が不安定になったりする可能性があります。

このような問題を根本解決してくれるのが **_Docker_** となってきます。

Dockerでは **_コンテナ_** と呼ばれる独立した「箱」を用意し、各コンテナの内部に **最小限のOSと必要な開発環境 (例えば PostgreSQL など)** を構築し、それぞれのコンテナを必要に応じて立ち上げることができます。メインのOSに直接インストールする場合と違って <span class="masked">Windowsレジストリの書き換え</span> などは起きません。

また、開発環境が不要になったときは、コンテナごときれいに削除することができます (ゴミが残ることがありません)。また `Dockerfile` や `docker-compose.yaml` という軽量の設定ファイル (テキストファイル) を残しておけば、すぐに開発環境を再構築することも可能となります。また、その設定ファイルを使って、別PCに上に開発環境のクローンを構築することも可能になります。

このように Docker (コンテナ型仮想化技術) には <span class="masked">普段使いのOS環境に影響を与えず、様々な開発環境を気軽に構築できる</span> というメリットがあります。

なお、コンテナ型仮想化技術の「詳しい仕組み」については、本科目では解説しないので興味関心がある学生は、書籍や生成AIなどを利用して各自で掘り下げてください。少し古い書籍ですが[仕組みと使い方がわかる Docker&Kubernetes のきほんのきほん](https://www.amazon.co.jp/dp/4839972745/)が初心者向けの内容になっており、お勧めです (研究室に所蔵しているので、内容を確認したい学生は声をかけてください)。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Docker に代表される「コンテナ型仮想化技術」とは、どのような技術ですか。

> Python では venv を使って仮想環境を構築して、ライブラリのバージョン管理ができます。また、Node.js では、package.json を用いて、プロジェクトフォルダ単位で npm パッケージのバージョン管理ができます。それらと、コンテナ型仮想化技術 (Docker) って何が違うのですか？ 

### Docker の活用法

Docker は、次のようなケースで、特に便利に利用することができます。

#### ケース1

例えば Python **3.10** でアプリを開発していたとします。このアプリが Python 3.7、3.8、3.9、3.11 といった**異なる実行環境でも正常に動作するかを確認したいとき**、Docker を利用すると便利です。各バージョンの Python 環境をコンテナとして簡単に用意できるため、複数バージョンでの動作確認を1台ので手軽に行うことができます。

#### ケース2

チーム開発のように「**全員の開発環境をそろえたい**」ときにも Docker は強力です。OS (Windows/macOS) やライブラリの違いによる「**自分の PC では動くのに、他の人のでは動かない…**」というトラブルを防ぐことができます。同じ Docker イメージ (`Dockerfile` や `docker-compose.yaml` ) を共有すれば、全員が限りなく同じ環境で開発することができます。

#### 参考書籍

Docker を使用して開発環境を構築するときは、以下の電子書籍が参考になると思います (KindleUnlimited対象 2025/10/09現在)。

- [Docker Desktop for Windows/Macでつくるクリーンな開発環境構築入門 (Webアプリケーション版) 2025版](https://www.amazon.co.jp/dp/B0F7WGR9RW/)
- [Docker Desktop for Windows/Macでつくるクリーンな開発環境構築入門 (Python版) 2025版](https://www.amazon.co.jp/dp/B08D8TXXHD/)

::: {.note .type-senior}

**VSCode を Dockerコンテナ 環境に接続して開発**

本科目では扱いませんが、VSCode の **Dev Containers** という拡張機能を利用すると、**VSCode から Dockerコンテナ内（Linux 環境）に直接接続して、プログラムの実行やデバッグを含む開発作業** を行うこともできます。

- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 識別子: `ms-vscode-remote.remote-containers`

![img](figs/02/vscode-01.png)

:::

### デメリット

各種環境を Windows に直接構築する場合と比較して、Docker を利用して環境構築することには、次のような**デメリット**があります。

- Docker そのものに対する「学習コスト」が大きい。
  - ただし、ソフトウェアエンジニアを目指すなら必要な学習投資です。
- システムリソースの消費が大きい。
- パフォーマンスのオーバーヘッドがある。
  - Windows や macOS では、Docker は仮想化レイヤ (Linux VM) を介して動作するため、ネイティブインストールと比較するとパフォーマンスが低下します。特に、ファイルI/O が頻繁に発生する処理、大量のデータを扱うデータベース操作などで影響があります。

## 授業時間外学習の指示 (宿題)

🚨**本科目は「学修単位科目」であり、1回の講義あたり、4時間相当の授業時間外学習が求められる科目です**🏃

- 次回の講義で「**小テスト**」を実施します。
- 講義のなかでは `docker container create` のコマンドオプションで、コンテナに対する各種設定を行いました。しかし、実務ではコマンドオプションではなく、代わりに `docker-compose.yaml` というファイルを作成し、そこに設定を記述するという方法が用いられます。`docker-compose.yaml` を使った Docker コンテナの作成と起動方法について調べてみてください。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> いま、Docker コンテナを `docker container run --name pg17 -e POSTGRES_USER=student -e POSTGRES_PASSWORD=secret123 -e POSTGRES_DB=playground -p 5432:5432 -d postgres:17.6` のように起動しています。これを `docker-compose.yaml` を使った方法に切り替えたいです。どのようにすればよいですか。

- 講義では、`postgres:17.6` という PostgreSQL の公式イメージを **そのまま利用** しましたが、実務では要件に合わせて独自のイメージを作成することが多く、その際に使われるのが `Dockerfile` となります。たとえば、追加パッケージの導入や、自分で用意した設定ファイル・サンプルデータのコピー、環境変数の設定、初期化スクリプトの配置などを行います。`Dockerfile` を用いた**カスタムイメージ作成**について調べてみてください。
  - [Dockerの基本を学んでコンテナ型の仮想環境を作ろう！](https://www.youtube.com/watch?v=B5tSZr_QqXw&t=1366s) @YouTube
    - **22:46** ～ Dokcerfile からコンテナを起動する解説 
  - Docker の `Dockerfile` や `docker-compose.yaml` のように、インフラの構成をプログラムコードとして記述し、管理・自動化する考え方を <span class="masked">IaC（Infrastructure as Code）</span> といいます。
- 次の動画では、Dockerの基礎知識から実際に開発環境を構築するまで徹底解説されています。おすすめです。
  - [【図解】これなら分かる!!はじめてのDocker](https://www.youtube.com/watch?v=B1EQ1oncKak)@YouTube

---

- この講義資料を再読・熟読し「不明な用語」や「理解が不十分な用語」があればインターネットや、ChatGPTなどの生成AIを利用して解決してください。また、興味関心を持ったトピックについて、ウェブ、生成AI、YouTube動画などを利用して知識を広げ、理解を深めてください。
  - 特に **<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例** を示しているものについては、実際に生成AIにプロンプトを投げ、さらに対話を重ねることで、知識の幅を広げるだけでなく、理解をより深く確かなものにしてください。
- 講義資料内の「演習」に再度取り組んでください。演習内容は、授業時間中に1回取り組むだけでは定着しないので注意してください。
