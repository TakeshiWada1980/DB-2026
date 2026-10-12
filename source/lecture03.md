---
var:
  header-title: "2026-4I データベース工学 第03回 講義資料"
  header-date: "2026年10月14日 (水) 1時限"
---

# 第03回 4I-データベース工学

## 連絡

- 小テスト❷ を実施します。
  - 遅刻・欠席等により「追試験」を希望する場合は [第01回講義で案内した手続き](lecture01.html#成績評価法と履修上の注意) に従ってください。

### 今回の達成目標

- VS Code から SQLファイルを実行する手順を理解し、自分で SQL を記述・実行して結果を確認できる。
- `SELECT` 文によるカラムの指定と、実行結果のカラム構成との対応を説明できる。
- 演算や条件分岐、`NULL` の扱い、重複の除外によって、実行結果がどう変わるかを確認できる。

## SQL演習環境の構築

[第02回講義](lecture02.html) では、PostgreSQL の **Dockerコンテナ** を作成・起動し、`docker container exec` コマンドを使って `psql` を実行しました。そして、`psql` の対話モード (コマンドライン入力) から、以下のような SQL を実行できることを確認しました。

- [テーブルの作成](lecture02.html#テーブルの作成-create-table)&ensp;  `CREATE`
- [レコードの挿入](lecture02.html#レコードの挿入-insert)&ensp;  `INSERT`
- [レコードの抽出](lecture02.html#レコードの抽出-select)&ensp;  `SELECT`

::: {.balloon .char-01 .face-02 .tone-yellow}
前回は、PostgreSQL を Docker コンテナ内で動作させていることや、そこにどのように接続して SQL を実行するのかを理解してもらうために、**あえて基本的なコマンドを1つずつ実行**する方法を体験してもらいました。

しかし、今後は、SQL の作成・編集・実行 (結果の確認) という作業を何度も繰り返してもらうため、**より快適で便利な実行環境** が必要になってきます。
:::

そこで、今回は、**VSCode 上で SQL を記述し、簡単な操作で PostgreSQL に対して実行できる環境** を構築していきます。さらに、TypeScript のプログラムから PostgreSQL に接続するための環境についても整えていきます。

### リポジトリのクローン

SQL の演習に十分な時間を確保するため、ゼロから環境を構築するのではなく、この授業の演習内容に合わせてあらかじめカスタマイズした環境を利用していきます。

ターミナル (PowerShell) を開いて「**SQL演習用の環境**」を配置したいフォルダ (例えば `C:\Users\xxxx\Documents` など) に移動してください。

- OneDrive で同期しているフォルダは、トラブルの原因になることがあるため避けてください。
- パスに日本語が含まれるフォルダも、トラブルの原因になることがあるため避けてください。

次のコマンドで、[SQL演習用環境 (教材)](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git) のリポジトリをクローンしてください。

```bash
git clone https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git DB-PostgreSQL
```

クローンが完了すると、現在のフォルダのなかに **DB-PostgreSQL** というフォルダが作成されます。次のコマンドでフォルダ内に移動して VSCode を起動してください。

```bash
cd DB-PostgreSQL
code .
```

### 依存関係のインストール

VSCode で `[Ctrl]+[J]` を押下してターミナルを開き、プロジェクトの実行に必要なパッケージをインストールしてください。

```bash
npm i
```

[プログラミング3](https://takeshiwada1980.github.io/Programming3-2025/) で学んだように、`npm i` は **package-lock.json** あるいは **package.json** に記述された情報をもとに、プロジェクトが依存するライブラリを自動でインストールするコマンドです。

- `npm install` と入力しても同じ意味になります。

### 環境変数の設定

プロジェクトのルートフォルダに **.env** (環境変数の設定ファイル) を新規作成してください。そして、**.env.dummy** の内容を参考に、次のように PostgreSQL への <span class="masked">接続文字列</span> を記述してください (改行せずに1行で記述してください。また `=` の前後にスペースを入れないでください)。

```ini{.numberLines caption=".env"}
DATABASE_URL="postgresql://student:secret123@localhost:5432/playground?schema=public"
```

上記の **データベース接続文字列** (DB Connection String) は **docker/docker-compose.yaml** に記述されたデフォルト設定に対応しています。

::: {.balloon .char-01 .face-05 .tone-blue}
このプロジェクトの **.gitignore** には、**.env** を Git の管理対象から除外する設定が書かれています。これは、**.env** に記載された機密情報 (パスワードや接続文字列) を、誤って GitHub に公開しないようにするためのものです。
:::


```yaml{.numberLines caption="docker/docker-compose.yaml (抜粋)" startFrom="6"}
environment:
  POSTGRES_USER: "student"
  POSTGRES_PASSWORD: "secret123"
  POSTGRES_DB: "playground"
```

- **docker-compose.yaml** は、複数の Docker コンテナの起動方法や、コンテナ間の接続・連携などをまとめて定義するための設定ファイルです。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> データベースに関する文脈で「接続文字列」とは何ですか？

> 次の docker-compose.yaml の内容を解説してください。  
> (ここに、プロジェクトのなかの docker/docker-compose.yaml の内容を貼り付ける)

#### 定着確認

- データベースへの「接続文字列」とは、どのような情報をまとめた文字列か答えよ。
  - **答え**: <span class="masked">接続先のホスト名やポート番号、データベース名、接続に使うユーザ名・パスワードなどの情報をまとめた文字列。</span>

- PostgreSQL への接続文字列が `postgresql://student:secret123@localhost:5432/playground?schema=public` である。この文字列に指定されている「接続先のホスト名」と「ポート番号」を答えよ。
  - **答え**: <span class="masked">ホスト名は `localhost`、ポート番号は `5432`。</span>

- Git において、**.env** などのファイルを管理対象から除外するために使用する設定ファイルの名前を答えよ。
  - **答え**: <span class="masked">.gitignore</span>

- Docker Compose で利用する **docker-compose.yaml** の役割として、最も適切な説明を選べ。**答え**: <span class="masked">❸</span>
  - ❶ 各コンテナで使うソフトウェアのインストールやファイルのコピーなどの手順を定義し、コンテナイメージを作成するための設定ファイル。
  - ❷ ホスト側のプログラムが接続先を選ぶためのホスト名・ポート番号・ユーザ名などを定義し、プログラムが読み込む接続情報をまとめるための設定ファイル。
  - ❸ 各コンテナで使うイメージ・環境変数・ポートの割り当てなどを定義し、複数のコンテナの起動方法や接続・連携をまとめるための設定ファイル。
  - ❹ 起動している各コンテナのイメージ・環境変数・ポートの割り当てなどを取得し、その時点の稼働状態を保存・復元するための設定ファイル。

### リモートリポジトリの作成

ウェブブラウザから自分の [GitHub](https://github.com/) にアクセスして、`DB-PostgreSQL` という名前で「空」の **パブリックリポジトリ** を作成してください。

この際、以下のように `README.md`、`.gitignore`、`LICENSE` などは含めずに、**完全に空の状態で作成**するようにしてください。

![img](figs/03/github-01.png)

作成したリポジトリのURL `https://github.com/xxxx/DB-PostgreSQL.git` をメモしておいてください。このあとで使用します。

### リモートリポジトリの設定変更

まず、現在のプロジェクトにおける **GitHub との連携設定** (リモートリポジトリの登録状況) を確認します。VSCode のターミナル (`[Ctrl]+[J]`) から、次のコマンドを実行してください。

```bash
git remote -v
```

次のような結果が表示されるはずです。

```text
origin  https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git (fetch)
origin  https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git (push)
```

以上より、現在、このプロジェクトでは、教員が教材として提供したリモートリポジトリが `origin` という名前で登録されていることがわかります。

::: {.balloon .char-01 .face-01 .tone-pink}
もし、この設定のまま `git push origin main` を実行すると、**教員のリポジトリに変更をプッシュしようとすることになります**。

実際には書き込み権限がないため拒否されますが...。
:::

そこで、**今後の演習で作成する SQL や プログラム などを、自分の GitHub リポジトリに記録・蓄積していけるように**、リモートリポジトリの設定を変更していきます。まず、次のコマンドで、教材用リポジトリの登録名を `origin` から `upstream` に変更してください。

```bash
git remote rename origin upstream
```

つづいて、先ほど作成した **自分のリモートリポジトリ**（`https://github.com/xxxx/DB-PostgreSQL.git`）を、新たに `origin` という名前で登録してください。

```bash
git remote add origin https://github.com/xxxx/DB-PostgreSQL.git
```

- 上記の `xxxx` は、自分の GitHub ユーザ名に置き換えてください。

その後、`main` ブランチを **プッシュ** してください。

```bash
git push -u origin main
```

最後に、ウェブブラウザから `https://github.com/xxxx/DB-PostgreSQL.git` にアクセスし、プッシュしたファイルが GitHub 上に反映されていることを確認してください。

---

ここまで適切に作業できていれば、`git remote -v` コマンドの応答が次のようになります。

```
origin  https://github.com/xxxx/DB-PostgreSQL.git (fetch)
origin  https://github.com/xxxx/DB-PostgreSQL.git (push)
upstream  https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git (fetch)
upstream  https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git (push)
```

::: {.balloon .char-01 .face-02 .tone-yellow}

上記は、現在のローカルリポジトリ (PCのプロジェクトフォルダ) が、**2つのリモートリポジトリ** と接続していることを示しています。

`origin` は **自分のGitHubアカウント上にあるリポジトリ** を指し、`upstream` は <span class="masked">教員が公開している元の教材配付リポジトリ</span> を指しています。

これにより、教材が更新されたときは `upstream` から `fetch` で変更を取り込み、自分の作業内容 (＝**演習や課題の取り組み**) は `origin` に `push` するような設定が完了しました。

:::

::: {.note .type-senior}

**中級者向け: upstream に対するプッシュを無効化する設定**

皆さんが誤って `upstream` に対してプッシュ操作しても、GitHub 側の権限設定によって操作は拒否されます (教材が書き換えられることはないので安心してください)。

より安全にするために、次のコマンドで、ローカル側で `upstream` に対するプッシュを無効化することもできます。

```bash
git remote set-url --push upstream DISABLED
```

この設定を行うと、`git remote -v` コマンドの出力は次のようになります。

```
origin  https://github.com/xxxx/DB-PostgreSQL.git (fetch)
origin  https://github.com/xxxx/DB-PostgreSQL.git (push)
upstream  https://github.com/TakeshiWada1980/DB-2026-PostgreSQL.git (fetch)
upstream  DISABLED (push)
```
:::

#### 定着確認

- ローカルリポジトリに登録されているリモートリポジトリの名前と、取得用・送信用のURLを一覧表示する Git コマンドを答えよ。
  - **答え**: <span class="masked">`git remote -v`</span>

- ローカルリポジトリに `origin` という名前で登録されているリモートリポジトリについて、その登録名を `upstream` に変更する Git コマンドを答えよ。
  - **答え**: <span class="masked">`git remote rename origin upstream`</span>

#### 教材の更新を取得するとき

[教材リポジトリ](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL) (`upstream`) が更新されたときは、次の手順で更新内容を自分のローカルリポジトリに取り込んでください。

::: {.note .type-caution}

**以下の作業をする前に自分側のファイル変更は、全てコミットするか、スタッシュしておいてください。**

:::

```bash
git fetch upstream
git switch main
git merge upstream/main
```

最後の `git merge upstream/main` コマンドを実行すると、以下のようにマージコミットのメッセージについての編集画面が表示されることがあります。その場合は、内容を確認して「続行」ボタンを押してください。

![img](figs/03/git-01.png)

マージが完了したら、**MERGE_MSG** のタブは閉じて問題ありません。

その後、VSCodeの「変更の同期」のボタンを押下するか、ターミナルで次のコマンドを実行して、自分のリモートリポジトリ (`origin`) に変更を反映させてください。

```bash
git push origin main
```

#### 演習や課題の成果を GitHub に記録するとき

今後の演習 (SQLドリル) や課題で作成・変更したファイルは、適宜コミットして、自分の GitHub リポジトリにプッシュしてください。基本的な操作は次のとおりです。

```bash
git add .
git commit -m "任意のコミットメッセージ"
git push
```

なお、これらの操作は VSCode の GUI から実行しても問題ありません。

## SQL整形のための VSCode の拡張機能の追加

SQL の整形 (フォーマット) のために **SQL Formatter VSCode** (識別子: `renesaarsoo.sql-formatter-vsc`) という拡張機能を VSCode にインストールしてください。

![img](figs/03/vscode-01.png)

この拡張機能と **.vscode/settings.json** の設定により、`.sql` ファイルの保存時に SQL が自動整形されるようになります。

```json{.numberLines caption=".vscode/settings.json (抜粋)"}
"[sql]": {
  "editor.defaultFormatter": "ReneSaarsoo.sql-formatter-vsc"
},
"SQL-Formatter-VSCode.keywordCase": "upper",
"SQL-Formatter-VSCode.denseOperators": false,
"SQL-Formatter-VSCode.linesBetweenQueries": 1,
"SQL-Formatter-VSCode.expressionWidth": 80,
"SQL-Formatter-VSCode.functionCase": "upper",
"SQL-Formatter-VSCode.logicalOperatorNewline": "after",
"SQL-Formatter-VSCode.dialect": "postgresql"
```

::: {.balloon .char-01 .face-04 .tone-blue}
この拡張機能は、記述形式を整えるためのものであり、SQL の文法的な誤りや処理内容を修正するものではありません。

**SQL が正しく実行できるかどうかは別途確認する必要があります。**
:::

### 任意： Code Spell Checker 拡張機能のインストール

SQLの演習のために [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) (識別子: `streetsidesoftware.code-spell-checker`) をインストールしておくことを推奨します。

この拡張機能は、コード内の**英単語のスペルミス**を検出して、控えめな下線表示で警告してくれるものです。テーブル名やカラム名は、原則として <span class="masked">英語</span> で記述するため、スペルミスを防ぐ目的でスペルチェッカを導入しておくと便利です。

![img](figs/03/vscode-05.png)

なお、Code Spell Checker では、正しい専門用語や略語であっても、辞書に登録されていない場合はスペルミスと判定されることがあります。このような誤検出があった場合は、**`.vscode/settings.json`** に該当する単語を登録することで、スペルミスとして判定されないようにできます。

- <i class="fa-brands fa-github"></i>[.vscode/settings.json](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/.vscode/settings.json) @ GitHub

## Docker コンテナの起動と終了

### 準備: Docker Desktop の起動確認 

はじめに Docker Desktop が起動済みで、ステータスが「**Running**」となっていることを確認してください。タスクトレイにアイコンが見つからない場合はスタートメニューから「Docker Desktop」を探して手動で起動してください。

![img](figs/01/docker-01.png)

### 準備: コンテナの確認と削除 (初回のみ)

前回講義で手動で作成した `pg18` というコンテナが残っていると、以降の作業に影響するので (コンテナの名前が衝突するので) 削除しておきます。

VSCode のターミナルから、次のコマンドで、停止中のものを含めて全てのコンテナを表示します。

```bash
docker ps --all
```

**NAMES** が `pg18` のコンテナがあれば、次のコマンドで削除してください。

```bash
docker container rm -fv pg18
```

### コンテナの起動

VSCode のターミナルから、次のコマンドで **PostgreSQL** と **DbGate** のコンテナを起動します。

```bash
npm run db:up
```

これは **package.json** の `scripts` に定義されたコマンドで、実際には次のような `docker compose` コマンドが実行されます。<i class="fa-brands fa-github"></i>[package.json](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/package.json) @ GitHub

```bash
docker compose -f docker/docker-compose.yaml -p pg18dev up -d --wait
```

::: {.balloon .char-01 .face-05 .tone-blue}
Docker Compose とは <span class="masked">複数の Docker コンテナをまとめて定義し、起動・停止などを一括して管理するための仕組み</span> です。コンテナの構成や接続設定などは **docker-compose.yaml** に記述されています。

- <i class="fa-brands fa-github"></i>[docker/docker-compose.yaml](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/docker/docker-compose.yaml) @ GitHub
:::

:::{.note .type-tips}
**docker compose コマンドのオプション**

- `-f docker/docker-compose.yaml`：使用する設定ファイルを指定します。
- `-p pg18dev`：Compose Project の名前を `pg18dev` に指定します。
- `up`：設定ファイルに従ってコンテナを作成・起動します。
- `-d`：コンテナをバックグラウンドで実行します。
- `--wait`：コンテナが起動状態 (またはヘルスチェックで正常と判定された状態) になるまで待機します。

なお、`docker compose` はコンテナを起動するたびに新しく作り直すわけではありません。すでにコンテナが存在する場合は、設定の変更状況などに応じて、既存のコンテナを再利用することもあります。
:::


`docker ps` コマンドで起動中のコンテナを確認すると、次のように表示されます (紙面の都合で COMMAND、CREATED、STATUS の3項目は省略しています)。

```
CONTAINER ID  IMAGE                PORTS                                         NAMES
5c87f5ffe47c  dbgate/dbgate:7.2.6  0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   dbgate7
045310a26441  pg18dev-postgres     0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   pg18
```

この表示から、**DbGate** (`dbgate7`) と **PostgreSQL** (`pg18`) の2つのコンテナが起動していることが分かります。

また、PORTS にはポートの割り当て状況が表示されています。`ホストのポート番号->コンテナのポート番号` という対応関係に注目してください。

- **DbGate**：ホストOS（Windows）の **8080番ポート** が、DbGate コンテナの **3000番ポート** にマッピングされています。
- **PostgreSQL**：ホストOS（Windows）の **5432番ポート** が、PostgreSQL コンテナの **5432番ポート** にマッピングされています。


::: {.note .type-senior}
**中級者向け：`0.0.0.0` と `[::]` の意味**

`PORTS` に表示される `0.0.0.0:8080->3000/tcp` は、ホスト側のすべての IPv4 アドレスで8080番ポートを待ち受ける設定を表しています。また、`[::]:8080->3000/tcp` は IPv6 に対応する表示です。

つまり、ポートを公開すると、Windows 上の自分のプログラムだけでなく、ネットワーク上の別の端末からもアクセスできる (アクセスされる) 可能性があります。実際に外部からアクセスできるかどうかは、Windows ファイアウォールなどの設定にも左右されます。
:::


Docker Desktop からも、次のように2つのコンテナが起動していることを確認できます。

![img](figs/03/docker-desktop-01.png)

::: {.balloon .char-01 .face-05 .tone-blue}

Docker Desktop では、`pg18dev` という **Compose Project（コンポーズプロジェクト）** のなかで、`dbgate7` と `pg18` の2つのコンテナが管理されていることが確認できます。

Compose Project とは、**Docker Compose でまとめて管理するコンテナやネットワーク、ボリュームなどを、1つのグループとして扱うための単位**です。今回の `pg18dev` という名前は、先ほどのコマンドの `-p pg18dev` によって指定されています。
:::

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Docker 初心者です。`docker compose up -d` の `-d` は「バックグラウンドで実行する」という意味だと習いました。「バックグラウンドで実行する」とはどういうことですか。

> Docker のポート公開について、`0.0.0.0` は「ホスト側のすべての IPv4 アドレス」、`[::]` は IPv6 に対応する表示だと習いました。しかし、「アドレスで待ち受ける」という言葉の意味が曖昧です。`0.0.0.0`、`[::]`、`127.0.0.1` の違いを説明してください。

#### 定着確認

- `docker ps` コマンドを実行した結果、あるコンテナの **PORTS** の項目が `0.0.0.0:8001->80/tcp` と表示された。これは、コンテナの `8001` 番ポートが、ホストの `80` 番ポートにマッピングされていることを示す。この説明は「適切である」か「適切ではない」か答えよ。
  - **答え**: <span class="masked">適切ではない</span>

- `npm run db:up` のように実行するコマンドは、プロジェクト内のどのファイルの、どの項目に定義されているか答えよ。
  - **答え**: <span class="masked">package.json の `scripts`。</span>

- 複数の Docker コンテナの構成を設定ファイルにまとめて定義し、起動・停止などを一括して管理するための仕組みを何というか答えよ。
  - **答え**: <span class="masked">Docker Compose</span>

- `docker compose -f docker/docker-compose.yaml -p pg18dev up -d --wait` というコマンドについて、`up` と `-d` の役割をそれぞれ答えよ。
  - **答え**: <span class="masked">`up` は設定ファイルに従ってコンテナを作成・起動する。`-d` はコンテナをバックグラウンドで実行する。</span>

- `docker compose -f docker/docker-compose.yaml -p pg18dev up -d --wait` というコマンドについて、`--wait` オプションは、サービスがどのような状態になるまで待機するためのものか答えよ。
  - **答え**: <span class="masked">起動状態、またはヘルスチェックが設定されている場合は正常と判定された状態になるまで待機する。</span>

- DbGate コンテナのポートを `0.0.0.0:8080->3000/tcp` として公開した。この場合、Windows 上の自分のプログラムだけがアクセスでき、ネットワーク上の別の端末からはアクセスできない。この説明は「適切である」か「適切ではない」か答えよ。
  - **答え**: <span class="masked">適切ではない。ネットワーク上の別の端末からもアクセスできる可能性がある。実際にアクセスできるかどうかは、Windows ファイアウォールなどの設定にも左右される。</span>

#### 演習

既にコンテナが起動しているとき、再度 `npm run db:up` コマンドを実行するとどうなるか確認してください。


### コンテナの停止

次のコマンドで **PostgreSQL** と **DbGate** の2つのコンテナ (Compose Project `pg18dev` 配下の全てのコンテナ) を**停止・削除**することができます。

```bash
npm run db:down
```

これも `package.json` の `scripts` に定義されたコマンドで、実際には次のような `docker compose` コマンドが実行されます。

```bash
docker compose -f docker/docker-compose.yaml -p pg18dev down
```

この `down` コマンドでは、コンテナに加えて、この Compose Project のネットワークも削除します。一方、データベースに保存された情報は <span class="masked">Docker の名前付きボリュームに永続化されているため、そのまま保持されます</span>。

そのため、再び `npm run db:up` を実行すると、新しいコンテナが作成され、残っている同じ名前付きボリュームを利用することで、前回のデータベースの内容を引き継ぐことができます。

Docker ボリュームの一覧は `docker volume ls` コマンドで確認ができます。また、Docker Desktop からも確認ができます。

![img](figs/03/docker-desktop-02.png)


::: {.balloon .char-01 .face-05 .tone-blue}
本科目では、Docker Volume については詳しく扱いませんが、実務で Docker を利用する場合、ボリュームは非常に重要な概念となります。関心のある学生は、YouTube や AI などを利用して概要だけでも把握しておくことをお勧めします。
:::

一方で、**データベースを初期状態に戻したい場合** は、次のコマンドで、この Compose Project のボリュームも含めて削除してください。

```bash
npm run db:reset
```

これも **package.json** の `scripts` に定義されたコマンドで、 `down` に `-v` オプションを付けたコマンドを実行します。

```bash
docker compose -f docker/docker-compose.yaml -p pg18dev down -v
```

- `npm run db:reset` を実行すると、この Compose Project の PostgreSQL と DbGate の名前付きボリュームも削除されます。これまでに作成したテーブルやレコードに加え、DbGate の保存設定も消去されます。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> 「Docker ではコンテナを削除しても、ボリュームを削除しない限り、データは永続化されて残り、同じボリュームを指定して再度コンテナを作成すれば、以前と同じデータを引き続き利用することができる」と聞きました。これは、どういうことですか。詳しく説明してください (>_<)/

## SQLファイルの実行

前のセクションでコンテナを停止している場合は、次のコマンドで再度起動しておいてください。

```bash
npm run db:up
```

第02回講義では、PostgreSQL の「CLI クライアントツール」である `psql` psql の対話モードで、SQL 文を直接入力 (またはコピー＆ペースト) して実行しました ( [参照](lecture02.html#psql-の対話モードで-postgresql-を操作) )。

しかし、この方法では、SQL の <span class="masked">再利用や修正がしづらく、実行内容の記録や共有にも適していません</span>。

そこで、**SQL をファイルに記述し、そのファイルを `psql` に読み込ませて実行する方法** を使います。

::: {.balloon .char-01 .face-02 .tone-yellow}
Python にも対話モードがありますが、ある程度まとまったプログラムを作成するときは、通常、`.py` ファイルにコードを書いて実行しますよね。

SQL についても同じように考えてください。
:::

### SQLファイルの作成

SQLファイルは、**拡張子を** `.sql` **として、原則として sql フォルダのなかに配置してください**。

ファイル整理の観点から、第03回講義では `03`、第04回講義では `04` のようなサブフォルダを作成し、そこに配置することを推奨します。なお、**フォルダやファイルの名前に日本語を使用すると予期せぬ不具合が生じる可能性がある**ので注意してください。

実際に、試してみましょう。SQL演習環境 (プロジェクトフォルダ) のなかに **sql/03/init-users.sql** を新規作成してください。

![img](figs/03/vscode-02.png)

ファイルに次の SQL を記述して保存してください。このファイルは、6つのSQL文から構成されています (文の区切りは `;` で判断してください)。

```sql{.numberLines caption="sql/03/init-users.sql"}
-- 第03回の演習で使うテーブルの格納先として、スキーマ w03 を作成する
CREATE SCHEMA IF NOT EXISTS w03;

-- 以降のSQLで使用するスキーマを指定する
SET search_path TO w03;

-- 既に同名のテーブルがあれば削除する
DROP TABLE IF EXISTS users;

-- ユーザ情報を保持するテーブルを作成する
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER);

-- テーブルにレコード（ユーザ情報）を挿入する
INSERT INTO
  users (id, name, age)
VALUES
  (1, 'Alice', 20),
  (2, 'Bob', 25);

-- すべてのレコードを抽出する
SELECT * FROM users;
```

::: {.balloon .char-01 .face-04 .tone-blue}
上記の SQL には、まだ詳しく学んでいない「スキーマ」や構文が含まれています。現段階では、すべての行を理解する必要はありません。まずは、**コメントを参考に処理の概要をつかみ、SQLファイルを作成・保存・実行する手順を確認**してください。
:::

ファイル保存の際、VSCode の拡張機能の [SQL Formatter VSCode](https://www.google.com/search?q=SQL+Formatter+VSCode) が有効に機能していれば、`SELECT` 文が以下のように自動整形されるはずです。

```sql{.numberLines caption="sql/03/init-users.sql（抜粋・自動整形後）" startFrom="21"}
-- すべてのレコードを抽出する
SELECT
  *
FROM
  users;
```

SQL Formatter VSCode の細かな挙動は、以下のファイルで設定 (カスタマイズ) が可能です。

- <i class="fa-brands fa-github"></i>[.vscode/settings.json](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/.vscode/settings.json) @ GitHub

### SQLファイルの実行

この SQL演習環境 において、さきほど作成した **sql/03/init-users.sql** は、次のコマンドにより **psql** に流し込んで実行可能です (実行できるように環境を構成・設定しています)。

```bash
npm run sql sql/03/init-users.sql
```

このコマンドが使えるのは、**package.json** の `scripts` に、SQLファイルを実行するための処理を `sql` という名前で定義しているためです。

- パスは **プロジェクトのルート**を基準に指定してください。
- 区切り文字 (パスセパレータ) には `\` と `/` のどちらも使用できます。

::: {.balloon .char-01 .face-02 .tone-yellow}
**.vscode/tasks.json** にビルドタスクを定義しているので、**init-users.sql** のエディタタブがアクティブな状態で `[Ctrl]+[Shift]+[B]` を押下することで、SQL を実行することもできるようになっています。<font color="deeppink"><b>頻繁に使用するショートカットなので、覚えておいてください。</b></font>


- `[B]` は <span class="masked">ビルド (Build)</span> の B です。
- <i class="fa-brands fa-github"></i>[.vscode/tasks.json](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/.vscode/tasks.json) @ GitHub

![img](figs/03/vscode-03.png)
:::

正常に実行されると、次のような応答が返ってきます。

```
> db-postgresql@1.0.0 sql
> tsx scripts/sqlFileRunner.ts sql\03\init-users.sql

CREATE SCHEMA
SET
DROP TABLE
CREATE TABLE
INSERT 0 2
 id | name  | age 
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
(2 行)
```

#### 演習

- 誤ったファイルパスを引数に `npm run sql ...` を実行するとどうなるか確認してください。
- コンテナが起動していない状態 (ただし、Docker Desktop は起動している状態) で `npm run sql ...` を実行すると (`[Ctrl]+[Shift]+[B]` のショートカットを実行すると) どうなるか確認してください。
- Docker Desktop が起動していない状態で `npm run sql ...` を実行すると (`[Ctrl]+[Shift]+[B]` のショートカットを実行すると) どうなるか確認してください。

### RDBMS における「スキーマ」という用語の2つの意味

データベースの分野では、**スキーマ (Schema) という用語が、大きく2つの意味で使われます**。文脈によって意味が異なるため、それぞれを区別して理解しておいてください。

#### ① 構造としてのスキーマ

テーブルのカラム名、データ型、制約、テーブル間の関係など「**データベースの論理的な構造を定義したもの**」を意味します。

例えば、`users` テーブルには `id`、`name`、`age` というカラムがあり、それぞれにデータ型 (整数、文字列、日付など) や制約 (非NULL制約、一意性制約など) が設定されている、といった構造の定義を指します。

#### ② 名前空間としてのスキーマ

PostgreSQL では、**1つのデータベースのなかに複数のスキーマを作成し、スキーマごとにテーブルなどを管理することができます**。この意味でのスキーマは「**名前空間 (Namespace)**」と呼ばれるもので、テーブルなどを名前によって区別・整理するための仕組みです。

一般的なデータベースの入門書では、RDBMS の構造について、次のように説明されることがあります。

- 1つの RDBMS は、複数の データベース を持つことができる。
- 1つの データベース は、複数の テーブル を持つことができる。

一方、PostgreSQL では、より正確には次のような階層構造になっています。

- 1つの PostgreSQL (RDBMS) は、複数のデータベースを持つことができる。
- 1つの データベース は、複数の スキーマ を持つことができる。
- 1つの スキーマ は、複数の テーブル を持つことができる。

:::{.note .type-tips}
PostgreSQL では、データベースを作成すると、標準で **public** という名前のスキーマが用意されます。<u>特にスキーマを指定しない場合、通常はこの **public** スキーマが使用されます</u>。
:::

たとえば、PostgreSQL では、次のような構造をとることができます。

```text
PostgreSQL（DBMS）
 └── データベース：playground
     ├── スキーマ：public
     ├── スキーマ：w03
     │   ├── テーブル：users
     │   └── テーブル：characters
     ├── スキーマ：w07
     │   ├── テーブル：users
     │   ├── テーブル：characters
     │   ├── テーブル：jobs
     │   ├── テーブル：items
     │   └── テーブル：character_items
     └── スキーマ：book
         └── 教科書の演習用の各種テーブル
```

異なるスキーマであれば <span class="masked">同じ名前のテーブルを作成すること</span> もできます。例えば、`w03.characters` と `w07.characters` は別々のテーブルであり、カラム構成や格納されているレコードが異なっていても問題ありません。

::: {.balloon .char-01 .face-02 .tone-yellow}
この授業では、名前空間としてのスキーマを利用して、**解説や演習で使用するテーブルを切り替えます**。

この講義資料では、**学習の進度に応じてテーブルのカラムやレコードを段階的に増やしていきます**。そのため、`w03`、`w07` などのスキーマを用意し、同じ名前でも構造やデータが異なるテーブルを使い分けます (`w03` は第03週目、`w07` は第07週目の意味です)。

また、教科書 (SQL ゼロからはじめるデータベース操作) のサンプルコードについては、原則として `book` スキーマを使用します。
:::

PostgreSQL では、次の SQL 文を使って、**スキーマ名を省略したときに、どのスキーマを参照するかを設定できます**。

```sql{.numberLines caption="優先参照するスキーマの切り替え"}
SET search_path TO w03;
```

これにより、以降、同一の SQL ファイルのなかで `SELECT * FROM users;` と記述したときには、`w03` スキーマ内の `users` テーブルが参照されるようになります。

::: {.balloon .char-01 .face-01 .tone-pink}
`SET search_path TO ...` による設定は、**SQL ファイル単位ではなく、接続 (セッション) 単位で有効**です。

ただし、この授業の演習環境では、SQL ファイルを実行するたびに新しい接続を使用します。そのため、実質的には、そのファイル内の `SET` 以降の SQL 文にだけ設定が適用されます。

別の SQL ファイルを実行するときは、ファイルの先頭で改めて指定してください。
:::

このように、**データベースへの接続先を変更することなく、演習で使用するテーブルを切り替えられる**ことが、名前空間としてのスキーマを利用するメリットとなります。

::: {.note .type-senior}
**中級者向け: MySQL におけるスキーマ**

「名前空間としてのスキーマ」の扱いは、RDBMS によって異なります。

例えば、MySQL では `DATABASE` と `SCHEMA` は同義であり、PostgreSQL のように1つのデータベース内に複数のスキーマを作成する構造にはなっていません。

MySQL でも `w03.users` や `book.users` のように名前を指定してテーブルを使い分けることができますが、この場合の `w03` や `book` は、それぞれ独立したデータベースを意味します。このように、同じ「スキーマ」という用語でも、DBMSによって意味や扱いが異なることに注意してください。

:::

#### 定着確認

- PostgreSQL で、1つのデータベース内に `w03` や `w07` というスキーマを作成し、スキーマごとにテーブルを区別・整理している。この場合のスキーマは「構造としてのスキーマ」と「名前空間としてのスキーマ」のどちらの意味か答えよ。
  - **答え**: <span class="masked">名前空間としてのスキーマ。</span>

- PostgreSQL の階層構造について「Table」「Database」「Schema」「RDBMS」の4つを、外側から内側への順に並べよ。
  - **答え**: <span class="masked">RDBMS 👉 Database 👉 Schema 👉 Table</span>

- PostgreSQL でデータベースを作成したとき、標準で用意されるスキーマの名前を答えよ。
  - **答え**: <span class="masked">public</span>

- PostgreSQL で `w03.users` と記述してテーブルを指定している。`w03` と `users` は、それぞれ何の名前か答えよ。
  - **答え**: <span class="masked">`w03` はスキーマ名、`users` はテーブル名。</span>

- PostgreSQL において、スキーマ名を省略したテーブル名の参照先を `w03` スキーマに設定するための SQL 文を記述せよ。
  - **答え**: <span class="masked">`SET search_path TO w03;`</span>

- PostgreSQL を標準設定で使用しており、スキーマの参照先の設定は変更していない。いま、同じデータベースのなかに `public.users` と `default.users`、`w03.users` がある。`SELECT * FROM users;` を実行した場合、どのテーブルが参照されるか答えよ。
  - **答え**: <span class="masked">`public.users`</span>

### GitHub Copilot の設定

SQLの構文理解やクエリ設計力を身につけるため、学習段階では SQL についての「GitHub Copilot の補完機能」を **_OFF_** にしておくことを推奨します。

![img](figs/03/vscode-04.png)

## TypeScriptファイルの実行

この SQL演習環境 において **TypeScriptファイル** は、基本的に `src` フォルダのなかに、必要に応じてサブフォルダを作成して配置してください。

例えば、`src/samples/helloWorld.ts` というファイルは、次のコマンドで実行できるようになっています。

```bash
npx tsx src/samples/helloWorld.ts
```

また、**ファイルの変更を検知して自動的に再実行したい場合** (＝ホットリロードを利用する場合) は、次のように `watch` を付けてコマンドを実行してください。停止する場合は、ターミナル上で `[Ctrl]+[C]` を入力してください。

```bash
npx tsx watch src/samples/helloWorld.ts
```

または、上記は、次のように npm スクリプト ( `package.json` で定義しているスクリプト) 経由で実行もできるようになっています。

```bash
npm run dev src/samples/helloWorld.ts
```

### 公式ドライバを用いたデータベース接続のサンプル

プロジェクトフォルダのなかの **src/samples/pgSample.ts** は、PostgreSQL と Node.js を接続するためのドライバである **pg** を利用した TypeScript の実装例です。

このサンプルは、**sql/03/init-users.sql** を実行して、**w03.users** テーブルを作成済みであることを前提としています。PostgreSQL コンテナが起動している状態で、VSCode のターミナルから次のコマンドを実行してみてください。

```bash
npx tsx src/samples/pgSample.ts
```

正常に実行できると、**w03.users** テーブルから取得した Alice と Bob の情報が表示されます。また、生成AIを活用してプログラムの読解にも挑戦してみてください。

- <i class="fa-brands fa-github"></i>[pgSample.ts](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/src/samples/pgSample.ts) @ GitHub

### Drizzle (ORM) を用いたデータベース接続のサンプル

プロジェクトフォルダのなかの **src/samples/drizzleSample.ts** は、**Drizzle** という ORM を使って PostgreSQL と接続する TypeScript の実装例です。このサンプルも、**w03.users** テーブルが作成済みであることを前提としています。

PostgreSQL コンテナが起動している状態で、VSCode のターミナルから次のコマンドを実行してみてください。

```bash
npx tsx src/samples/drizzleSample.ts
```

こちらも **w03.users** テーブルから Alice と Bob の情報を取得して表示します。また、生成AIを活用してプログラムの読解にも挑戦してみてください。**pgSample.ts** と見比べて、テーブルの指定やデータの取得をどのように記述しているか確認してみてください。

- <i class="fa-brands fa-github"></i>[drizzleSample.ts](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/src/samples/drizzleSample.ts) @ GitHub

::: {.balloon .char-01 .face-02 .tone-yellow}
プログラミング3 では、**Prisma** という ORM を使いました。Prisma と Drizzle は、どちらも TypeScript のプログラムからデータベースを操作するための ORM ですが、**<u>テーブル構造の定義方法やデータの取得方法に違いがあります</u>**。

**Prisma** では、**`schema.prisma`** にテーブルやカラムに対応するモデルを定義し、`npx prisma generate` で **Prisma Client** を生成しました。そして、`prisma.category.findMany()` のように、モデルに対応するメソッドを使ってデータを取得していました。

一方、**Drizzle** では、テーブルやカラムの構造を **TypeScript のコードで定義** します。今回のサンプルでは、`w03.table("users", ...)` でテーブル構造を定義し、`db.select().from(usersTable)` でデータを取得しています。この書き方は、SQL の `SELECT ... FROM ...` と対応づけて理解することができます。
:::

本科目で、Prisma ではなく Drizzle を採用しているのは、**SQL と TypeScript のコードの対応関係を理解しやすい** ためです。まずは **`pgSample.ts`** と **`drizzleSample.ts`** を見比べて、同じデータ取得処理がそれぞれどのように記述されているかを確認してください。

以上で、SQL 演習環境の構築の話は終了です。

## レコードの抽出

ここからは 本格的に **SQL** (**Structured Query Language**) について学んでいきます。

まずは、RDB に対する各種操作 (クエリ) のなかでも、利用頻度の最も高い **レコードの抽出操作** (`SELECT` 文) について学んでいきます。

- RDB に関する文脈において **クエリ** (**Query**) とは、データベースに対する <span class="masked">「要求」「操作」「問い合わせ」</span> を SQL (＝Structured **Query** Language) により記述したものを意味します。

### 準備: テーブルの作成とレコードの挿入

プロジェクトフォルダ内の `from-teacher/03/init-characters.sql` を、`sql/03/init-characters.sql` にコピーしてください。

その後、ターミナルから次のコマンドを実行するか、このファイルのタブがアクティブな状態で `[Ctrl]+[Shift]+[B]` を押下して、SQL を実行してください。

```bash
npm run sql sql/03/init_characters.sql
```

- コマンドの応答を確認し、エラーが発生していないことを確認してください。正常に実行処理できていれば `CREATE TABLE`、`INSERT 0 xx` のような応答が返ってきます。 
  - PostgreSQL からのエラーメッセージを **<u>英語表示</u>** にしたい場合は `npm run sql:en (ファイル名)` のようにコマンドを実行してください。  
```bash
npx tsx src/samples/drizzleSample.ts
```

::: {.balloon .char-01 .face-05 .tone-blue}
この `init-characters.sql` のなかには、**characters** というテーブルを作成する `CREATE` 文と、そのテーブルにレコードを挿入する `INSERT` 文が記述されています。

これら `CREATE` 文や、`INSERT` 文についての詳しい内容は、次週以降の授業で扱っていきます。現段階では、簡単に目を通しておくだけで大丈夫です。
::: 

この **characters** (キャラクタ) テーブルは、次のような **8つのカラム** から構成されています。このあと、このテーブルに対して問い合わせをする `SELECT` 文を書いていくので、概要は簡単に把握しておいてください。

1. `id`: **レコードを一意に識別するID**。整数型。主キー。<span class="masked">自動採番</span> され `NULL` は不可。
2. `name`: **キャラクタ名**。最大16文字の可変長文字列型。`NULL` は不可。
    - 標準 SQL において、格納可能な最大文字数が決められた **可変長文字列型** を <span class="masked">VARCHAR型</span> といいます。
3. `job`: **ジョブ (職業)**。最大16文字の可変長文字列型。`NULL` は不可。
4. `level`: **レベル**。整数型で、1〜99 の範囲に制約。`NULL` は不可。
5. `buff`: **バフ（能力補正係数）**。全体で3桁、小数部 2 桁の固定小数点数型。`NULL` は不可。
    - 具体的には `-9.99` 〜 `9.99` が格納可能。
6. `guild`: **所属ギルド名**。最大 32 文字の可変長文字列型。
7. `last_login_at`: **最終ログイン日時**。日時型。
    - 標準 SQL において、年・月・日と時刻 (時・分・秒) を格納するデータ型を <span class="masked">TIMESTAMP型</span> といいます。
    - PostgreSQL では、さらに <span class="masked">タイムゾーン情報</span> も格納する **TIMESTAMPTZ型** も存在します。`TIMESTAMPTZ` は、標準 SQL の `TIMESTAMP WITH TIME ZONE` の別名 (エイリアス) となっています。
8. `created_on`: **キャラクタ作成日**。日付型 (時刻情報を含まない)。
    - 標準 SQL において、時刻を含まず「年月日」を格納するデータ型を **DATE型** といいます。

[http://localhost:8080/](http://localhost:8080/) もしくは [http://127.0.0.1:8080/](http://127.0.0.1:8080/) から「**DbGateコンテナ**」にアクセスして、**characters** テーブルの内容を確認してみてください。

![img](figs/03/dbgate-01.png)

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL の `psql` で SQL を実行したところ、`CREATE TABLE`、`INSERT 0 19` のようなレスポンスが返ってきました。これらの意味を解説してください。

#### 定着確認

- 標準 SQL において、タイムゾーン情報を含まず日付 (年・月・日) と時刻 (時・分・秒) を格納するデータ型を答えよ。大文字で答えること。
  - **答え**: <span class="masked">TIMESTAMP。TIMESTAMP WITHOUT TIME ZONE でも可。</span>
- 標準 SQL において、時刻を含まず、「年月日」を格納するデータ型を答えよ。大文字で答えること。
  - **答え**: <span class="masked">DATE</span>
- 標準 SQL において、格納可能な最大文字数が決められた可変長文字列型を答えよ。大文字で答えること。
  - **答え**: <span class="masked">VARCHAR</span>

### SELECT文

テーブルから任意のレコード (行) を取り出す操作を、RDB では **_選択_** (**Selection**) と呼びます。また、任意のカラム (列) だけを取り出す操作を **_射影_** (**Projection**) と呼びます。これらの操作は **SQL** (=Structured Query Language) では `SELECT` キーワードによって指示します。

::: {.note .type-caution}

**第1稿で、上記の「選択」を、誤って「抽出」と書いていました。訂正します。**

:::

**s_characters** テーブルに格納されたすべての情報 (すべてのレコードとカラム) を取得するには、次のような `SELECT` 文 (SQLクエリ) を使用します。

```sql{.numberLines caption="s_charactersのすべてのレコードとカラムを取得"}
SELECT * FROM s_characters;
```

この `SELECT` 文 は、次のように「改行」や「インデント」で整形して記述することもできます。

```sql{.numberLines caption="s_charactersのすべてのレコードとカラムを取得 (整形)"}
SELECT
  *
FROM
  s_characters;
```

- `sql/03/tmp.sql` を作成し、上記のコードを貼り付け、実際に実行してみてください。

本科目の演習環境では、拡張機能[SQL Formatter VSCode](https://marketplace.visualstudio.com/items?itemName=ReneSaarsoo.sql-formatter-vsc)により、ファイル保存時に改行形式に自動整形されます。

#### 定着確認

- テーブルから必要なレコード (行) を取り出す操作を何というか。漢字2文字で答えよ。
  - 答え: <span class="masked">選択。英語では Selection。※第1稿では誤って「抽出」としていましたが、「選択」が正しいです。</span>
- テーブルから必要なカラム (列) を取り出す操作を何というか。漢字2文字で答えよ。
  - 答え: <span class="masked">射影。英語では Projection</span>
- テーブルから必要なレコードを取得する際に使用する SQL の命令 (キーワード) を答えよ。大文字のアルファベットで答えること。
  - 答え: <span class="masked">SELECT</span>

### 任意のカラムのみを取得 (射影)

`SELECT` 文では、テーブルに含まれるカラムのうち「**どのカラムを取り出すか (射影するか)**」を明示的に指定することができます。これは、先ほど `*` を書いていた位置に **カンマで区切って「カラム名」を並べる**ことで可能になります。

例えば、`id` と `name` と `guild` の3つのカラムについてのみレコードを取得したいときには、次のような `SELECT` 文 (SQLクエリ) を使用します。

```sql{.numberLines caption="任意のカラムだけを取得(1)"}
SELECT
  id,
  name,
  guild
FROM
  s_characters;
```

また、次のように <span class="masked">同じカラムを2回以上指定</span> したり、表示順を自由に指定したりすることも可能です。

```sql{.numberLines caption="任意のカラムだけを取得(2)"}
SELECT
  name,
  guild,
  job,
  name
FROM
  s_characters;
```

なお、`SELECT name, job, FROM s_characters;` のように、<span class="masked">最後のカラム名のあとにカンマを付けてしまうと</span>、**構文エラー** (Syntax Error) となるので注意してください。

#### SQLドリル💻

- `ex-01_1.sql` 👉 **s_characters** テーブルのすべてのレコードについて `id`、`name`、`level`、`created_on` を取得する SQL 文を記述し、実行せよ。なお、問題文に示した順番でカラムが並ぶようにすること。
- `ex-01_2.sql` 👉 **s_characters** テーブルのすべてのレコードについて `id`、`last_login_at`、`created_on`,
`id` を取得する SQL 文を記述し、実行せよ。なお、問題文に示した順番でカラムが並ぶようにすること。

**SQLドリル**💻は、プロジェクトのなかに `sql/03/drill/ex-01_1.sql` のようなファイルを作成して取り組むことを推奨します。解答例 (参考) は `from-teacher` フォルダのなかに配置しています。

- SQLドリルについては、**文法や構文を体で覚える観点から**、GitHub Copilot のコード補完を切って、コピペも避けて SQL を手入力することを推奨します。

### カラムに別名 (エイリアス) をつける

次のように `SELECT` 句において、カラム名のあとに `AS "xxxx"` をつけることで、その**カラムに別名 (エイリアス) を付けること**ができます。この別名は <span class="masked">クエリ結果として表示されるカラムのヘッダ (ラベル)</span> としても使用されます。

カラム名に記号やスペースが含まれない場合はダブルクォートを省略可能ですが、本科目 (小テストや試験を含む) のなかでは安全のため常にダブルクォートで囲むようにしてください。

```sql{.numberLines caption="カラムにエイリアスを設定"}
SELECT
  id,
  name AS "名前", -- ◀◀ ここに注目
  guild AS "所属ギルド" -- ◀◀ ここに注目
FROM
  s_characters;
```

実行結果 (上位5件のみ抜粋) は、次のようになります。

```
 id |  名前   | 所属ギルド 
----+---------+------------
  1 | Marvin  | Yamato
  2 | Zach    | D.D.D
  3 | Charlie |
  4 | Tom     |
  5 | Ivan    |
```

- `AS` につづく文字列を **ダブルクォート** ではなく **シングルクォート** で囲んで実行した場合、どのようになるかを確認してください。

#### SQLドリル💻

- `ex-02_1.sql` 👉 **s_characters** テーブルのすべてのレコードについて `id`、`name`、`level`、`job` を取得する SQL 文を記述し、実行せよ。なお、カラムは問題文に示した順序で並ぶようにし、それぞれのカラムのヘッダ (ラベル) が「ID」「名前」「レベル」「ジョブ」となるようにせよ。
- `ex-02_2.sql` 👉 **s_users** テーブルのすべてのレコードについて `id`、`name`、`age` を取得する SQL 文を記述し、実行せよ。なお、カラムは問題文に示した順序で並ぶようにし、それぞれのカラムのヘッダ (ラベル) が「出席番号」「名前」「年齢」となるようにせよ。

### SQLの文法上の注意

SQL では、`--` を使って **コメント** を記述します。また、`/*    */` で囲んで複数行のコメントアウトができます。VSCode では <span class="masked">`[Ctrl]+[/]`</span> のショートカットでコメントの設定と解除ができます。

SQL では、**1つの文の終わり**を示すためにセミコロン `;` を使用します。実行環境によってはセミコロンを省略できることもありますが、**本科目の小テストや試験のなかでは、必ずセミコロンをつけるようにしてください** (セミコロン抜けは誤答や減点とします)。

PostgreSQL において `SELECT` や `FROM` などの「**キーワード**」は <span class="masked">大文字と小文字を区別しません</span>。また、テーブル名やカラム名などの「**識別子** (例えば `s_characters` や `id` など)」も**大文字と小文字を区別しません**。

  - ただし、**識別子**はダブルクォート `"` で囲んだ場合のみ、大文字と小文字が「**区別される**」ので注意してください。

::: {.note .type-tips}

**SQLの「文」と「句」について**

次のような SQL があるとき、これ全体を「**SELECT文**」と言います。また、文を構成している `SELECT id, name, age` の部分を「**SELECT句**」といい、`FROM s_users` の部分を「**FROM句**」といいます。

```sql{.numberLines caption="SQL: SELECT文"}
SELECT id, name, age FROM s_users;
```

同様に、次のような SQL があるとき、全体を「**INSERT文**」と言います。また `INSERT INTO s_users (id, name, age)` を「**INSERT INTO句**」といい、`VALUES (1, 'Alice', 20), (2, 'Bob', 25)` を「**VALUES句**」といいます。

```sql{.numberLines caption="SQL: INSERT文"}
INSERT INTO
  s_users (id, name, age)
VALUES
  (1, 'Alice', 20),
  (2, 'Bob', 25);
```

:::

#### 定着確認

いま、`s_users` というテーブルに `id`、`name`、`age` というカラムが存在している。

- このとき `select id, name form s_users;` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーになる。`form` ではなく `from` が正しい。</span>
- このとき `select id, name, age, from s_users;` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーになる。`age` のあとのカンマが不要。</span>
- このとき `select NAME, AGE, ID from S_users;` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーにならない。テーブル名やカラム名などの「識別子」は大文字と小文字を区別しない。</span>
- このとき `SELECT "name", "age" FROM "s_users";` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーにならない。</span>
- このとき `SELECT "Name", age FROM s_users;` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーになる。識別子をダブルクォートで囲むと大文字と小文字が区別される。</span>
- このとき `SELECT 'name', 'age' FROM s_users;` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーにならない。ただし `SELECT name, age FROM s_users;` とは大きく結果が変わってくるので注意すること。後述の定数値カラムの扱いになる。</span>
- このとき `SELECT * FROM 's_users';` という SQL は「構文エラーになる」か「構文エラーにならない」かを答えよ。
  - **答え**: <span class="masked">構文エラーになる。</span>

いずれのケースも、実際に SQL を実行して結果を確認してみてください (＝どのようなエラーメッセージが表示されるのか把握しておいてください)。

### 定数値カラムを付加する

`SELECT` 文では、**実際のテーブルには存在しない「定数値」をカラムとして追加して出力**することもできます。

このとき、定数値として「**文字列**」を使うときは **シングルクォート** `'` で囲んでください。一方で、`AS` によるカラムのエイリアス指定では **ダブルクォート** `"` を用いる点も注意してください。

```sql{.numberLines caption="定数値カラムを付加"}
SELECT
  8 AS "RegionID", -- 定数値のカラム
  'Zipangu' AS "World", -- 定数値のカラム
  id AS "ID",
  name AS "名前"
FROM
  s_characters;
```

実際に実行して結果を確認してください。

::: {.note .type-tips}

**注意**

**SELECT句** において...

- **シングルクォート**で囲んだ `'Zipangu'` は、文字列リテラル (固定値) を表します。
    - 「Zipangu」という「**文字列そのもの**」を意味します。
- **ダブルクォート**で囲んだ `"Zipangu"` は <span class="masked">識別子 (カラム名やテーブル名など)</span> を表します。
    - 「Zipangu」という名前の「カラム」を意味します。

:::

#### SQLドリル💻

- `ex-03_1.sql` 👉 **s_characters** テーブルのすべてのレコードについて、次に示すようなチェックリストを出力する SQL を記述せよ。

```
 id |  name   | level | buff  |  不正行為の疑い?  
----+---------+-------+-------+-------------------
  1 | Marvin  |    35 | -0.15 | 要調査 / 問題なし
  2 | Zach    |    62 |  0.10 | 要調査 / 問題なし
  3 | Charlie |    57 |  0.00 | 要調査 / 問題なし
  4 | Tom     |     1 |  0.00 | 要調査 / 問題なし
  5 | Ivan    |    39 | -0.07 | 要調査 / 問題なし
 ～～ 以下略 ～～
```

- `ex-03_2.sql` 👉 **s_users** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。
  - age カラムの出力 (`XX歳`) には、次のセクションで解説する「**文字列の結合**」を使用する必要があります。

```
 grade | course | name  | age  
-------+--------+-------+------
     4 | M      | Alice | 20歳
     4 | M      | Bob   | 25歳
```

### カラム値に文字列演算と算術演算を適用する

次に示すように、`SELECT` 句では `||` 演算子を使用して「**文字列の結合 (連結)**」ができます。これにより、複数のカラム値や文字列リテラルを組み合わせて、ひとつの文字列として出力することができます。

```sql{.numberLines caption="文字列演算"}
SELECT
  name || ' (' || Job || ')' AS "Name(Job)",
  'Lv.' || level AS "Level"
FROM
  s_characters;
```

実行結果 (上位5件のみ抜粋) は、次のようになります。

```
    Name(Job)     | Level 
------------------+-------
 Marvin (Priest)  | Lv.35
 Zach (Ninja)     | Lv.62
 Charlie (Wizard) | Lv.57
 Tom (Fighter)    | Lv.1
 Ivan (Monk)      | Lv.39
``` 

また、**数値型のカラム**については基本的な算術演算も可能です。

```sql{.numberLines caption="算術演算"}
SELECT
  id AS "ID", 
  name AS "Name",
  buff AS "Buff",
  (buff + 1) * 100 || '%' AS "BuffApplied(%)"
FROM
  s_characters;
```

実行結果 (上位5件のみ抜粋) は、次のようになります。

```
 ID |  Name   | Buff  | BuffApplied(%) 
----+---------+-------+----------------
  1 | Marvin  | -0.15 | 85.00%
  2 | Zach    |  0.10 | 110.00%
  3 | Charlie |  0.00 | 100.00%
  4 | Tom     |  0.00 | 100.00%
  5 | Ivan    | -0.07 | 93.00%
```

`ROUND()` 関数を使えば、桁数を指定しての四捨五入ができます。例えば、`BuffApplied(%)` を「**整数値\%**」で出力したい場合は、次のようにします。

```sql{.numberLines caption="ROUND()による四捨五入"}
SELECT
  id AS "ID", 
  name AS "Name",
  ROUND((buff + 1) * 100, 0) || '%' AS "BuffApplied(%)"
FROM
  s_characters;
```

その他、切り上げ `CEIL()`、切り捨て `FLOOR()` などの関数が利用できます。詳しくは、PostgreSQL の公式ドキュメント (リファレンス) を参照してください。

- [Table 9.4. Mathematical Operators](https://www.postgresql.org/docs/current/functions-math.html#FUNCTIONS-MATH-OP-TABLE)
- [Table 9.5. Mathematical Functions](https://www.postgresql.org/docs/current/functions-math.html#FUNCTIONS-MATH-FUNC-TABLE)

#### SQLドリル💻

- `ex_04-1.sql` 👉 **s_characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。

```
 id |        summary
----+------------------------
  1 | Marvin (Priest Lv.35)
  2 | Zach (Ninja Lv.62)
  3 | Charlie (Wizard Lv.57)
  4 | Tom (Fighter Lv.1)
  5 | Ivan (Monk Lv.39)
 ～～ 以下略 ～～
```

- `ex_04-2.sql` 👉 **s_characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。ただし、**Boosted Level** は **level** を「1.2倍」にして切り上げた値とすること。

```
 id | Level | Boosted Level 
----+-------+---------------
  1 |    35 |            42
  2 |    62 |            75
  3 |    57 |            69
  4 |     1 |             2
  5 |    39 |            47
```

#### 定着確認

- **products** というテーブルに **value** という数値型のカラムがある。このカラムの値を **小数第3位**で四捨五入して、**小数第2位**までを取得する `SELECT` 文として、以下のSQLを完成させたい。`【 X 】` に記述すべき語を答えよ。
  - **答え**: <span class="masked">`ROUND(value, 2)`</span>

```sql{.numberLines caption="SQL"}
SELECT
  value,
  【 X 】AS "Rounded Value"
FROM
  products;
```

### CASE式を利用する

`SELECT` 句では「**CASE式**」というものを利用して <span class="masked">条件に応じて異なる値を出力すること</span> ができます。この「**CASE式**」は `SELECT` 句に限らず、SQL のなかで**条件分岐を実現するための強力な仕組み**で、実務でも頻繁に利用されています。

```sql{.numberLines caption="CASE式による条件分岐"}
SELECT
  id,
  name,
  level,
  CASE
    WHEN level >= 80 THEN 'SS'
    WHEN level >= 60 THEN 'S'
    WHEN level >= 40 THEN 'A'
    ELSE 'B'
  END AS "class"
FROM
  s_characters;
```

実行結果 (上位5件のみ抜粋) は、次のようになります。

```
 id |  name   | level | class 
----+---------+-------+-------
  1 | Marvin  |    35 | B
  2 | Zach    |    62 | S
  3 | Charlie |    57 | A
  4 | Tom     |     1 | B
  5 | Ivan    |    39 | B
```

`WHEN` 句の「評価式」では **値の等価比較** に `==` ではなく `=` を使用する点に注意してください。一般的なプログラミング言語とは異なり、SQL では `=` が「等しい」を意味します。一方で「等しくない」ことを判定したいとき、PostgreSQL では `!=` または `<>` が使用できます (標準SQLでは `<>` が正式な記法とされています)。また、評価式では `AND` や `OR` を利用することができます。

なお、「**値が** `NULL` **かどうか**」を評価するためには、以下のように `IS NULL` を使用します (`ISNULL`も可)。`guild = NULL` のように評価することはできないので十分に注意してください。

```sql{.numberLines caption="NULL判定の評価式"}
SELECT
  id,
  name,
  CASE
    WHEN guild IS NULL THEN '(無所属)' -- NULL判定には IS NULL を使用
    ELSE guild
  END AS "guild"
FROM
  s_characters;
```

実行結果 (上位5件のみ抜粋) は、次のようになります。

```
 id |  name   |  guild   
----+---------+----------
  1 | Marvin  | Yamato
  2 | Zach    | D.D.D
  3 | Charlie | (無所属)
  4 | Tom     | (無所属)
  5 | Ivan    | (無所属)
```

#### SQLドリル💻

- `ex-05_1.sql` 👉 **s_characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、**battle_position** は **job** が「Fighter」「Samurai」「Monk」「Ninja」のときに「frontline」、それ以外のときに「backline」となるようにすること。

```
 id |  name   |   job   | battle_position 
----+---------+---------+-----------------
  1 | Marvin  | Priest  | backline
  2 | Zach    | Ninja   | frontline
  3 | Charlie | Wizard  | backline
  4 | Tom     | Fighter | frontline
  5 | Ivan    | Monk    | frontline
 ～～ 以下略 ～～
```

- `ex-05_2.sql` 👉 **s_characters** テーブルのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、**status** は **buff** が、0.0 のときは「--」、負数の場合は「debuff」、正数の場合は「buff」となるようにすること。

```
 id |  name   | buff  | status 
----+---------+-------+--------
  1 | Marvin  | -0.15 | debuff
  2 | Zach    |  0.10 | buff
  3 | Charlie |  0.00 | --
  4 | Tom     |  0.00 | --
  5 | Ivan    | -0.07 | debuff
 ～～ 以下略 ～～
```

- `ex-05_3.sql` 👉 **s_characters** テーブルのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、**class** は以下の条件により決定すること。
  - `Master` : **level** が「50」以上、かつ、**created_on** が「2022/12/31」以前
  - `Veteran` : `Master` の条件を満たさず、**level** が「30」以上、かつ、**created_on** が「2023/12/31」以前
  - `Rookie` : `Master` の条件も、`Veteran` の条件も満たさない

```
 id |  name   | level | created_on |  class  
----+---------+-------+------------+---------
  1 | Marvin  |    35 | 2020-09-23 | Veteran
  2 | Zach    |    62 | 2020-10-25 | Master
  3 | Charlie |    57 | 2020-12-05 | Master
  4 | Tom     |     1 | 2020-12-05 | Rookie
  5 | Ivan    |    39 | 2021-02-15 | Veteran
 ～～ 以下略 ～～
```

### NULLを別の値に変換する

前のセクションで説明したように「CASE式」を利用して `NULL` を任意の値に置き換えることができました。これと同じ処理は `COALESCE` (コアレス) という関数でシンプルに行なうことができます。

`COALESCE` は <span class="masked">引数のなかから、最初に見つかった `NULL` ではない値を返す関数</span> となります。引数を左から順に評価し、`NULL` ではない値が見つかった時点で、それを結果として返します。

たとえば、次のように書くと、**guild** の値が `NULL` の場合にだけ `(無所属)` が表示されるようになります。

```sql{.numberLines caption="COALESCE関数によるNULLの変換"}
SELECT
  id,
  name,
  guild,
  COALESCE(guild, '(無所属)') AS "所属"
FROM
  s_characters;
```

実行結果 (上位5件のみ抜粋) は、次のようになります。

```
 id |  name   | guild  |   所属   
----+---------+--------+----------
  1 | Marvin  | Yamato | Yamato
  2 | Zach    | D.D.D  | D.D.D
  3 | Charlie |        | (無所属)
  4 | Tom     |        | (無所属)
  5 | Ivan    |        | (無所属)
```

#### SQLドリル💻

- `ex-06_1.sql` 👉 **s_characters** テーブルのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、**guild or (name)** の値は、次の条件に従って決定すること。`CASE` 式は使用せず、`COALESCE` 関数を用いること。
  - **guild** が `NULL` でない場合は、その値 (**guild**) を表示する。
  - **guild** が `NULL` の場合は、**name** を括弧で囲んで表示する。

```
 id |  name   | guild  | guild or (name) 
----+---------+--------+---------------
  1 | Marvin  | Yamato | Yamato
  2 | Zach    | D.D.D  | D.D.D
  3 | Charlie |        | (Charlie)
  4 | Tom     |        | (Tom)
  5 | Ivan    |        | (Ivan)
 ～～ 以下略 ～～
```


### レコードの重複を省く

次の SQL を実行すると、**s_characters** テーブルのすべてのレコードの `job` カラムの値を取得することができます。

```sql{.numberLines caption="jobカラムのみの出力"}
SELECT
  job
FROM
  s_characters;
```

具体的な実行結果は、次のようになります。

```
   job   
---------
 Priest
 Ninja
 Wizard
 Fighter
 Monk
 Priest
 Fighter
 Monk
 Samurai
 Fighter
 Wizard
 Samurai
 Wizard
 Ninja
 Priest
 Samurai
 Fighter
 Priest
 Wizard
(19 行)
```

ここで、`SELECT` 句に `DISTINCT` (ディスティンクト) キーワードを使うと <span class="masked">重複するレコードを省いて結果を取得すること</span> ができます。

```sql{.numberLines caption="DISTINCTによる重複の除外"}
SELECT DISTINCT -- ◀◀ ここに注目
  job
FROM
  s_characters;
```

この場合の実行結果は次のようになります。

```
   job   
---------
 Samurai
 Ninja
 Wizard
 Fighter
 Monk
 Priest
(6 行)
```

#### SQLドリル💻

- `ex-07_1.sql` 👉 **s_characters** テーブルから、キャラクタが所属しているギルドの一覧を取得する SQL を記述せよ。なお、`NULL` は「未所属」として出力すること。

```
 ギルド 
--------
 未所属
 Yamato
 hameln
 D.D.D
```

- `ex-07_2.sql` 👉 **s_characters** テーブルから、次のように各ギルドに所属しているジョブを重複を除いて取得する SQL を記述せよ。なお、ギルドが `NULL` のときは「未所属」として出力すること。

```
 ギルド | ジョブ  
--------+---------
 未所属 | Wizard
 D.D.D  | Wizard
 D.D.D  | Ninja
 hameln | Fighter
 hameln | Monk
 Yamato | Priest
 hameln | Wizard
 未所属 | Priest
 D.D.D  | Fighter
 未所属 | Fighter
 Yamato | Samurai
 Yamato | Fighter
 hameln | Samurai
 未所属 | Monk
 未所属 | Samurai
(15 行)
```

### 日付・時刻関数を利用する (授業時間外学習)

TIMESTAMP型のデータから「年」「月」「日」「時」「分」「秒」を「**数値**」として得たいときは `DATE_PART` 関数を使用します。

```sql{.numberLines caption="日付と時刻の分解"}
SELECT
  name,
  last_login_at,
  DATE_PART('year', last_login_at) AS "year",
  DATE_PART('month', last_login_at) AS "month",
  DATE_PART('day', last_login_at) AS "day",
  DATE_PART('hour', last_login_at) AS "hour",
  DATE_PART('minute', last_login_at) AS "minute",
  DATE_PART('second', last_login_at) AS "second"
FROM
  s_characters;
```

- `DATE_PART` 関数は、標準SQLに含まれない PostgreSQL 独自の関数です。
- `DATE_PART` 関数は、`DATE` 型のデータから「年」「月」「日」を取得する場合にも使用できます。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> 標準SQLを使って、TIMESTAMP型のカラム (`last_login_at`) から「年」「月」「日」「時」「分」「秒」を個別に数値として取得したいです。どのような SQL を書けばよいですか。

一方で、TIMESTAMP型のデータから「年」「月」「日」「時」「分」「秒」を「**文字列**」として得たいときは `TO_CHAR` 関数を使用します。DATE型のデータについても使用することができます。

```sql{.numberLines caption="日時のフォーマット(文字列整形)"}
SELECT
  name,
  last_login_at,
  TO_CHAR(last_login_at, 'YYYY"/"MM"/"DD HH24"時"MI"分"SS"秒"')
FROM
  s_characters;
```

上記の **第04行目** で使用している `YYYY` や `MI` などの「**フォーマット指定子**」は、PostgreSQL の公式ドキュメント (リファレンス) を参照してください。

- [Table 9.27. Template Patterns for Date/Time Formatting](https://www.postgresql.org/docs/current/functions-formatting.html#FUNCTIONS-FORMATTING-DATETIME-TABLE)

なお、フォーマット指定子以外の文字 (書式内でそのまま出力したい文字列) は <span class="masked">ダブルクォート</span> で囲むようにしてください。そのまま記述しても正しく出力される場合もありますが、確実に意図どおり表示させるためにはダブルクォートで囲むことが推奨されます。

#### SQLドリル💻

- `ex-08_1.sql` 👉 **s_characters** テーブルのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、**created_on** は `2020-09-01` 以降の日付であることを仮定してよい。
  - ヒント: 和暦 (令和) の年は、西暦の値から <span class="masked">2018</span> を引くことで求めることができる。

```
 id |  name   | created_on_1 |  created_on_2   
----+---------+--------------+-----------------
  1 | Marvin  | 2020-09-23   | 令和2年09月23日
  2 | Zach    | 2020-10-25   | 令和2年10月25日
  3 | Charlie | 2020-12-05   | 令和2年12月05日
  4 | Tom     | 2020-12-05   | 令和2年12月05日
  5 | Ivan    | 2021-02-15   | 令和3年02月15日
 ～～ 以下略 ～～
```

#### 定着確認

- あるテーブルに **created_at** という `TIMESTAMP` 型のカラムが存在する。このカラムの値を `2025年10月16日` のような書式の「文字列」として取得したい。PostgreSQL を想定し、`SELECT` 句にどのような関数や式を用いればよいか答えよ。
  - **答え**: `SELECT` <span class="masked">`TO_CHAR(created_at, 'YYYY"年"MM"月"DD"日"')`</span> `AS "created_at" FROM ...;`   
- あるテーブルに **created_on** という `DATE` 型のカラムが存在する。このカラムから「年」の値を「数値型」として取得したい。PostgreSQL を想定し、具体的にどのような関数や式を用いればよいか答えよ。
  - **答え**: <span class="masked">`DATE_PART('year', created_on)`。なお、戻り値は `DOUBLE PRECISION` 型 (実数) となるので、整数にしたい場合は `DATE_PART('year', created_on)::INT` のようにキャストします。</span>

### 現在日時と日数・時間の差を計算する (授業時間外学習)

- 現在の日時を取得するには `LOCALTIMESTAMP` (`TIMESTAMP`型) を使用します。
  - `CURRENT_TIMESTAMP` を使用すると **タイムゾーン情報付き** の (`TIMESTAMPTZ`型) になるので注意してください。
- 現在の時刻を取得するには `LOCALTIME` (`TIME`型) を使用します。
  - `CURRENT_TIME` を使用するとタイムゾーン情報付きの (`TIMETZ`型) になるので注意してください。
- 現在の日付 (**時刻を含まない**) を取得するには `CURRENT_DATE` (`DATE`型) を使用します。
  - `CURRENT_DATE` は、もともとタイムゾーン情報を含みません。

いま、**s_characters** の **created_on** カラムは「タイムゾーン情報なしの `DATE` 型」、**last_login_at** カラムは「タイムゾーン情報なしの `TIMESTAMP` 型」で型定義しています。そのため、`s_characters` に関して **現在の日時を基準に日時の差分を取りたい場合**は `LOCALTIMESTAMP` を、**日付の差分を取りたい場合**は `CURRENT_DATE` を用いるのが安全です。

- テーブルのカラムが **タイムゾーン情報付き型** である場合は、`CURRENT_TIMESTAMP` や `CURRENT_TIME` を使用するべきです。

::: {.note .type-senior}

**datetime value function (日時値関数) について**

`LOCALTIMESTAMP`、`CURRENT_DATE`、`LOCALTIME` は **datetime value function (日時値関数)** というもので、通常は、括弧を付けずに呼び出す特別な形式の関数式になります。括弧は `LOCALTIME(0)` のように精度を指定する場合にのみ用いられ、`LOCALTIME()` のように引数なしにすると PostgreSQLでは構文エラーになります。

:::

::: {.note .type-senior}

**タイムゾーン情報の扱いについて**

タイムゾーン情報を「含める」か「含めない」かはシステム設計において非常に重要な判断になります。また、その影響は DB だけでなく、**DB に接続するアプリケーションの設計や挙動にも直接関わります**。たとえば、サーバとクライアントが異なる地域にある場合、DB 側でタイムゾーンを考慮しない設計をしてしまうと、アプリで表示される時刻が「数時間ずれる」といった問題が発生します。

LOCALTIMESTAMP と CURRENT_TIMESTAMP の違いなどは `sql/03/tmp.sql` に、以下のコードを貼り付け、確認してみてください。

```sql{.numberLines caption="日時値関数の比較"}
SELECT
  LOCALTIMESTAMP(0) AS "LOCALTIMESTAMP",
  CURRENT_TIMESTAMP(0) AS "CURRENT_TIMESTAMP";

SELECT
  LOCALTIME(0) AS "LOCALTIME",
  CURRENT_TIME(0) AS "CURRENT_TIME";

SELECT
  CURRENT_DATE AS "CURRENT_DATE";
```

:::

例えば、登録日 (`created_on`) から本日までの経過日数を得たいとき、以下の **第05行目** のように `CURRENT_DATE` を使用します。`DATE` 型同士の減算 (`DATE - DATE`) の結果は <span class="masked">整数型 (日数差)</span> となります。

```sql{.numberLines caption="登録日からの経過日数の取得"}
SELECT
  id,
  name,
  created_on,
  CURRENT_DATE - created_on AS "Days Since Created"
FROM
  s_characters;
```

また、最終ログイン (`last_login_at`) から現在日時までの経過時間を得たいとき、以下の **第05行目** のように `LOCALTIMESTAMP` を使用します。`TIMESTAMP` 同士の減算 (`TIMESTAMP - TIMESTAMP`) の結果は `INTERVAL` 型になります。

```sql{.numberLines caption="最終ログインからの経過時間"}
SELECT
  id,
  name,
  last_login_at,
  LOCALTIMESTAMP - last_login_at AS "Elapsed Time Since Last Login"
FROM
  s_characters;
```

`INTERVAL` 型は、`DATE` 型や `TIMESTAMP` 型と同様に、`DATE_PART` 関数や `TO_CHAR` 関数と組みあわせて利用することができます。

---

`TIMESTAMP` 型は、次のように `DATE` 型にキャスト (型変換) することができます。

```sql{.numberLines caption="TIMESTAMPをDATEに変換"}
SELECT
  id,
  name,
  last_login_at,
  CAST(last_login_at AS DATE) AS "last_login_at(DATE型)"
FROM
  s_characters;
```

- PostgreSQL では `CAST(last_login_at AS DATE)` を <span class="masked">`last_login_at::DATE`</span> のように記述することができます (標準SQL構文ではない)。 

なお、`DATE` 型や `TIMESTAMP` 型の値を直接指定したい場合は、`CAST` 関数を使って文字列から型を明示的に変換します。たとえば、`DATE` 型のリテラルは `CAST('2025-04-01' AS DATE)`、`TIMESTAMP` 型のリテラルは `CAST('2025-04-01 13:05:59' AS TIMESTAMP)` のように記述します。

```sql{.numberLines caption="DATEリテラル"}
SELECT
  id,
  name,
  CAST('2026-03-31' AS DATE) - CURRENT_DATE || '日' AS "卒業まであと"
FROM
  s_users;
```

#### SQLドリル💻

- `ex-09_1.sql` 👉  **s_characters** テーブルのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。ただし、**最終ログイン** は「2025年10月15日」を基準として計算すること。

```
 id |  name   |    last_login_at    | 最終ログイン 
----+---------+---------------------+--------------
  1 | Marvin  | 2025-07-24 13:31:00 | 83日前
  2 | Zach    | 2025-07-30 18:33:00 | 77日前
  3 | Charlie | 2025-07-29 20:37:00 | 78日前
  4 | Tom     |                     |
  5 | Ivan    | 2025-07-18 19:29:00 | 89日前
 ～～ 以下略 ～～
```

- `ex-09_2.sql` 👉 **s_characters** テーブルのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。ただし、**Days Since Last Login** は「2025年10月15日」を基準として計算し、**Is Active User?** は最終ログインから「50日以内か」で判断すること。

```
 id |  name   | Last Login | Days Since Last Login | Is Active User? 
----+---------+------------+-----------------------+-----------------
  1 | Marvin  | 2025-07-24 | 83 days ago           | No
  2 | Zach    | 2025-07-30 | 77 days ago           | No
  3 | Charlie | 2025-07-29 | 78 days ago           | No
  4 | Tom     |            |                       | No
  5 | Ivan    | 2025-07-18 | 89 days ago           | No
  6 | Alice   | 2025-09-18 | 27 days ago           | Yes
  7 | Trudy   | 2025-09-29 | 16 days ago           | Yes
 ～～ 以下略 ～～
```

#### 定着確認

- 標準 SQL において、現在の日時をタイムゾーン情報なしの `TIMESTAMP` 型の値として参照したい。どのような日時値関数を用いればよいか答えよ。
  - **答え**: <span class="masked">`LOCALTIMESTAMP`</span>
- 標準 SQL において、現在の日付を `DATE` 型の値として参照したい。どのような日時値関数を用いればよいか答えよ。
  - **答え**: <span class="masked">`CURRENT_DATE`</span>

## 授業時間外学習の指示 (宿題)

🚨**本科目は「学修単位科目」であり、1回の講義あたり「4時間相当」の授業時間外学習が求められる科目です**🏃

- 次回の講義で「**小テスト❸**」を実施します。
  - **定着確認** および **SQLドリル** から主に出題します。
  - 講義が進行するにつれて、当然ながら小テストの内容も複雑で高度なものになっていきます。前半で、しっかりと得点をとるようにしてください。

---

- この講義資料を再読・熟読し「不明な用語」や「理解が不十分な用語」があればインターネットや、ChatGPTなどの生成AIを利用して解決してください。また、興味関心を持ったトピックについて、ウェブ、生成AI、YouTube動画などを利用して知識を広げ、理解を深めてください。
  - 特に **<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例** を示しているものについては、実際に生成AIにプロンプトを投げ、さらに対話を重ねることで、知識の幅を広げるだけでなく、理解をより深く確かなものにしてください。
- 講義資料内の「**演習**」や「**SQLドリル**」に再度取り組んでください。特に、**SQLドリル**💻 は、授業時間中に1回取り組むだけでは定着しないので注意してください。
