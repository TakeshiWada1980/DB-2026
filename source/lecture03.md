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

なお、`docker compose up` は、実行するたびにコンテナを再作成するわけではありません。既存のコンテナがあり、設定などに変更がなければ、そのコンテナを再利用します。
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

- `npm run db:reset` を実行すると、**<u>この Compose Project の PostgreSQL と DbGate の名前付きボリュームも削除</u>**されます。これまでに作成したテーブルやレコードに加え、DbGate の保存設定も消去されます。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> 「Docker ではコンテナを削除しても、ボリュームを削除しない限り、データは永続化されて残り、同じボリュームを指定して再度コンテナを作成すれば、以前と同じデータを引き続き利用することができる」と聞きました。これは、どういうことですか。詳しく説明してください (>_<)/

## SQLファイルの実行

前のセクションでコンテナを停止している場合は、次のコマンドで再度起動しておいてください。

```bash
npm run db:up
```

第02回講義では、PostgreSQL の「CLI クライアントツール」である `psql` の対話モードで、SQL 文を直接入力 (またはコピー＆ペースト) して実行しました ( [参照](lecture02.html#psql-の対話モードで-postgresql-を操作) )。

しかし、この方法では、SQL の <span class="masked">再利用や修正がしづらく、実行内容の記録や共有にも適していません</span>。

そこで、**SQL をファイルに記述し、そのファイルを `psql` に読み込ませて実行する方法** を使用します。

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
CREATE TABLE users (id INTEGER PRIMARY KEY, name VARCHAR(16) NOT NULL, age INTEGER);

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

ここからは、本格的に **SQL** (**Structured Query Language**) について学んでいきます。

まずは、RDB に対する各種操作 (クエリ) のなかでも、利用頻度の最も高い **レコードの抽出操作** (`SELECT` 文) について学んでいきます。

- RDB に関する文脈において **クエリ** (**Query**) とは、データベースに対する <span class="masked">「要求」「操作」「問い合わせ」</span> を SQL (＝Structured **Query** Language) により記述したものを意味します。

### 準備: テーブルの作成とレコードの挿入

プロジェクトフォルダ内の `from-teacher/03/init-characters.sql` を、`sql/03/init-characters.sql` にコピーしてください。

- <i class="fa-brands fa-github"></i>[from-teacher/03/init-characters.sql](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/from-teacher/03/init-characters.sql) @ GitHub

その後、ターミナルから次のコマンドを実行するか、このファイルのタブがアクティブな状態で `[Ctrl]+[Shift]+[B]` を押下して、**SQL を実行**してください。

```bash
npm run sql sql/03/init-characters.sql
```

- コマンドの応答を確認し、エラーが発生していないことを確認してください。正常に実行処理できていれば `CREATE TABLE`、`INSERT 0 xx` のような応答が返ってきます。 
  - PostgreSQL からのエラーメッセージを **<u>英語表示</u>** にしたい場合は、以下のようにコマンドを実行してください。  
```bash
npm run sql:en [ファイル名]
```

::: {.balloon .char-01 .face-05 .tone-blue}
この `init-characters.sql` のなかには、**characters** というテーブルを作成する `CREATE` 文と、そのテーブルにレコードを挿入する `INSERT` 文が記述されています。

これら `CREATE` 文や、`INSERT` 文についての詳しい内容は、次週以降の授業で扱っていきます。現段階では、簡単に目を通しておくだけで大丈夫です。
::: 

この **characters** (キャラクタ) テーブルは、次のような **8つのカラム** から構成されています。このあと、このテーブルに対して問い合わせをする `SELECT` 文を書いていくので、概要は簡単に把握しておいてください。

1. `id`: **レコードを一意に識別するID**。整数型 (**INTEGER**)。主キー。<span class="masked">自動採番</span> され `NULL` は不可。
2. `name`: **キャラクタ名**。最大16文字の可変長文字列型。`NULL` は不可。
    - 標準 SQL において、格納可能な最大文字数が決められた **可変長文字列型** (**VARCHAR(16)**) を <span class="masked">VARCHAR型</span> といいます。
3. `job`: **ジョブ (職業)**。最大16文字の可変長文字列型。`NULL` は不可。
4. `level`: **レベル**。整数型で、1〜99 の範囲に制約。`NULL` は不可。
5. `buff`: **バフ（能力補正係数）**。全体で3桁、小数部 2 桁の固定小数点数型 (**NUMERIC(3, 2)**)。`NULL` は不可。
    - 具体的には `-9.99` 〜 `9.99` が格納可能。
6. `guild`: **所属ギルド名**。最大 32 文字の可変長文字列型。
7. `last_login_at`: **最終ログイン日時**。日時型 (**TIMESTAM**`)。
8. `created_on`: **キャラクタ作成日**。時刻情報を含まない「年」「月」「日」のみの日付型 (**DATE**)。`NULL` は不可。
 
::: {.note .type-tips}

**TIMESTAMP型 と TIMESTAMPTZ型**

標準 SQL において、タイムゾーン情報を含まず、年・月・日と時刻 (時・分・秒) を格納するデータ型を **_TIMESTAMP型_** といいます。この **characters** テーブルの `last_login_at` カラムには、この型を使用しています。

一方、PostgreSQL には **_TIMESTAMPTZ型_** もあり、こちらは、入力した日時を UTC (Coordinated Universal Time、協定世界時) に変換して保存し、<u>表示するときには</u> **現在のセッションに設定されているタイムゾーン** に合わせて変換する型です。入力時のタイムゾーン名や時差そのものは保存されません。

- `TIMESTAMPTZ` は、標準 SQL の `TIMESTAMP WITH TIME ZONE` の別名 (エイリアス) です。
- TIMESTAMPTZ型の表示には、通常は PostgreSQL 側で設定されたデフォルトのタイムゾーン情報が使用されますが、`SET TIME ZONE` で明示的に指定しているときは、そちらが優先されます。
- この SQL 演習環境では <i class="fa-brands fa-github"></i>[**docker\docker-compose.yaml**](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/docker/docker-compose.yaml) の **第10行目** にある `TZ: Asia/Tokyo` をもとに、初回のデータベース初期化時にタイムゾーンのデフォルトが設定されます。

:::

[http://localhost:8080/](http://localhost:8080/) もしくは [http://127.0.0.1:8080/](http://127.0.0.1:8080/) から「**DbGateコンテナ**」にアクセスして、**characters** テーブルの内容を確認してみてください。

![img](figs/03/dbgate-01.png)

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL の TIMESTAMPTZ型は「タイムゾーン情報付き」の型なので、入力時の「日本時間」「ニューヨーク時間」といった地域名や時差も、そのまま保存されると思っていました。この理解は正しいですか。実際に保存されるものと保存されないもの、表示時に参照される設定を整理し、TIMESTAMP型との違いも説明してください。

> PostgreSQL における主要なデータ型 (標準 SQL と互換性のあるもの) について紹介してください。

#### 定着確認

- 標準 SQL において、タイムゾーン情報を含まず日付 (年・月・日) と時刻 (時・分・秒) を格納するデータ型を答えよ。大文字で答えること。
  - **答え**: <span class="masked">TIMESTAMP。TIMESTAMP WITHOUT TIME ZONE でも可。</span>
- 標準 SQL において、時刻を含まず、「年月日」を格納するデータ型を答えよ。大文字で答えること。
  - **答え**: <span class="masked">DATE</span>
- 標準 SQL において、格納可能な最大文字数が決められた可変長文字列型を答えよ。大文字で答えること。
  - **答え**: <span class="masked">VARCHAR</span>

- PostgreSQL の `TIMESTAMPTZ` は、標準 SQL のどのデータ型の別名か答えよ。
  - **答え**: <span class="masked">`TIMESTAMP WITH TIME ZONE`</span>

- PostgreSQL の TIMESTAMPTZ 型では、入力された日時を特定の時間基準に変換したうえで保存する。その時間基準をアルファベット3文字で答えよ。
  - **答え**: <span class="masked">UTC</span>

- PostgreSQL の TIMESTAMPTZ型には、日時だけでなく、入力時のタイムゾーン名や時差そのものも保存される。この説明は「適切である」か「適切ではない」か答えよ。
  - **答え**: <span class="masked">適切ではない。日時は UTC に変換して保存され、入力時のタイムゾーン名や時差そのものは保持されない。</span>

- PostgreSQL に保存した TIMESTAMPTZ型の日時を表示するとき、どのタイムゾーンに合わせて変換されるか答えよ。
  - **答え**: <span class="masked">現在のセッションに設定されているタイムゾーン。通常は PostgreSQL 側のデフォルト値が使われるが、`SET TIME ZONE` で明示的に指定した場合は、そちらが優先される。</span>

### SELECT文

テーブルから任意のレコード (行) を取り出す操作を、RDB では **_選択_** (**Selection**) と呼びます。また、任意のカラム (列) だけを取り出す操作を **_射影_** (**Projection**) と呼びます。SQL では、これらの操作に `SELECT` 文を使用します。

ここでは、先ほど作成した **w03.characters** テーブル (w03 スキーマの characters テーブル) から、すべてのレコードとカラムを取得してみます。

#### SELECT文の作成と実行

まず、**sql/03/tmp.sql** というファイルを作成し、次の SQL を記述して保存してください。

```sql{.numberLines caption="sql/03/tmp.sql"}
SET search_path TO w03;

SELECT * FROM characters;
```

つづいて、VSCode の **tmp.sql のタブがアクティブな状態**で `[Ctrl]+[Shift]+[B]` を押して実行してください。または、プロジェクトルートで次のコマンドを実行してください。

```bash
npm run sql sql/03/tmp.sql
```

初期データのままであれば、**19件のレコード**について、`id` から `created_on` までの **8つのカラム** が表示されるはずです。先ほど DbGate で確認したテーブルの内容と照らし合わせ、同じデータが取得できていることを確認してください。

#### SELECT文の基本的な書き方

先ほど実行した SQL のうち、データを取得しているのは次の部分です。

```sql{caption="sql/03/tmp.sql"}
SELECT * FROM characters;
```

`SELECT` の後の `*` は「**すべてのカラム**」、`FROM` の後の `characters` は「**データの取得元となるテーブル**」を指定しています。また、この例ではレコードを絞り込む条件 (<span class="masked">`WHERE`句</span>) を指定していないため、**テーブル内のすべてのレコードが取得されます**。

::: {.balloon .char-01 .face-05 .tone-yellow}
ここで使用している **characters** テーブルは、**w03** スキーマのなかにあります。このテーブルは、`w03.characters` のようにスキーマ名を含めて指定することで明示的に参照できます。

一方、今回の SQL ファイルでは、先頭で `SET search_path TO w03;` を実行しています。そのため、以降の SQL 文ではスキーマ名を省略し、`characters` と記述するだけで同じテーブルが参照可能となっています。

以降の演習でも、**SQL ファイルの先頭で使用するスキーマを設定し、各 SQL 文ではスキーマ名を省略する**という書き方を基本とします。
:::

#### SQLの整形

SQL 文は、次のように「改行」や「インデント」を使って整形することもできます。**改行やインデントを変更しても、SQL の実行結果は変わりません**。この SQL 演習環境では、拡張機能 [SQL Formatter VSCode](https://marketplace.visualstudio.com/items?itemName=ReneSaarsoo.sql-formatter-vsc) により、ファイルを保存すると SQL が自動的に整形されます。

```sql{.numberLines caption="sql/03/tmp.sql（整形後）"}
SET
  search_path TO w03;

SELECT
  *
FROM
  characters;
```

#### 定着確認

- テーブルから必要なレコード (行) を取り出す操作を何というか。漢字2文字および英語で答えよ。
  - **答え**: <span class="masked">選択、Selection。</span>
- テーブルから必要なカラム (列) を取り出す操作を何というか。漢字2文字および英語で答えよ。
  - **答え**: <span class="masked">射影、Projection。</span>
- テーブルから必要なレコードを取得する際に使用する SQL の命令 (キーワード) を答えよ。大文字のアルファベットで答えること。
  - **答え**: <span class="masked">SELECT</span>

- `SELECT * FROM w03.characters;` の `*` は何を指定しているか答えよ。
  - **答え**: <span class="masked">対象とするテーブルに存在する全てのカラム。</span>

- PostgreSQL で、SQLファイルの先頭で使用するスキーマを **w03** に設定し、そのファイル内で `characters` のようにスキーマ名を省略してテーブルを参照したい。このために記述する SQL 文を答えよ。
  - **答え**: <span class="masked">`SET search_path TO w03;`</span>

- PostgreSQL の **w03** スキーマにある **characters** テーブルから、すべてのレコードとカラムを取得する SQL 文を記述せよ。ただし、`SET search_path` を使用せず、スキーマ名を明示すること。
  - **答え**: <span class="masked">`SELECT * FROM w03.characters;`</span>

- PostgreSQL の `SELECT * FROM w03.characters;` という SQL 文において、`w03` と `characters` はそれぞれ何の名前か答えよ。
  - **答え**: <span class="masked">w03 はスキーマ名、characters はテーブル名。</span>

### 任意のカラムのみを取得 (射影)

`SELECT` 文では、テーブルに含まれるカラムのうち「**どのカラムを取り出すか (射影するか)**」を明示的に指定することができます。これは、先ほど `*` を書いていた位置に **カンマで区切って「カラム名」を並べる**ことで可能になります。

例えば、すべてのレコードについて、`id`、`name`、`guild` の3つのカラムだけを取得したいときには、次のような `SELECT` 文 (SQLクエリ) を使用します。

```sql{.numberLines caption="任意のカラムだけを取得 (1)"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  guild
FROM
  characters;
```

また、次のように <span class="masked">同じカラムを2回以上指定</span> したり、カラムの表示順を自由に指定したりすることも可能です。

```sql{.numberLines caption="任意のカラムだけを取得 (2)"}
SET
  search_path TO w03;

SELECT
  name,
  guild,
  job,
  name
FROM
  characters;
```

なお、`SELECT name, job, FROM characters;` のように、<span class="masked">最後のカラム名のあとにカンマを付けてしまうと</span>、**構文エラー** (Syntax Error) となるので注意してください。

#### SQLドリル💻

- `ex-01_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて `id`、`name`、`level`、`created_on` を取得する SQL 文を記述し、実行せよ。なお、問題文に示した順番でカラムが並ぶようにすること。
- `ex-01_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて `id`、`last_login_at`、`created_on`、`id` を取得する SQL 文を記述し、実行せよ。なお、問題文に示した順番でカラムが並ぶようにすること。

::: {.balloon .char-01 .face-02 .tone-yellow}

**SQLドリル**💻は、プロジェクトのなかに `sql/03/drill/ex-01_1.sql` のようなファイルを作成して取り組むことを推奨します。解答例 (参考) は `from-teacher` フォルダのなかに配置しています。
:::

- SQLドリルについては、**文法や構文を体で覚える観点から**、GitHub Copilot のコード補完を切って、コピペも避けて SQL を手入力することを推奨します。

### カラムに別名 (エイリアス) をつける

次のように `SELECT` 句において、カラム名のあとに `AS "別名"` をつけることで、その**カラムに別名 (エイリアス) を付けること**ができます。

```sql{.numberLines caption="カラムにエイリアスを設定"}
SET
  search_path TO w03;

SELECT
  id,
  name AS "名前", -- ◀◀ ここに注目
  guild AS "所属ギルド" -- ◀◀ ここに注目
FROM
  characters;
```

この別名 (エイリアス) は <span class="masked">クエリ結果として表示されるカラムのヘッダ (ラベル)</span> としても使用されます。例えば、`name AS "名前"` と指定すると、`name` カラムの値が「**名前**」というヘッダで表示されます。なお、エイリアスは SQL の実行結果に対して一時的に付けられる名前であり、元のテーブルのカラム名が変更されるわけではありません。

::: {.balloon .char-01 .face-01 .tone-pink}
PostgreSQL では、エイリアスをダブルクォートで囲むことで、**日本語やスペースを含む名前を指定することができます**。エイリアスのダブルクォートは省略できる場合もありますが、<font color="deeppink"><b>本科目 (小テストや試験を含む) のなかでは常にダブルクォートで囲むようにしてください</b></font>。
:::

上記の SQL の実行結果から、`id` が1〜5のレコードを抜粋すると、次のようになります。

```
 id |  名前   | 所属ギルド 
----+---------+------------
  1 | Marvin  | Yamato
  2 | Zach    | D.D.D
  3 | Charlie |
  4 | Tom     |
  5 | Ivan    |
```

- レコードの表示順は、上記と異なる場合があります。
- `name AS "名前"` を `name AS '名前'` のように、**ダブルクォート** ではなく **シングルクォート** で囲んで実行した場合、どのようになるかを確認してください。

#### SQLドリル💻

- `ex-02_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて `id`、`name`、`level`、`job` を取得する SQL 文を記述し、実行せよ。なお、カラムは問題文に示した順序で並ぶようにし、それぞれのカラムのヘッダ (ラベル) が「ID」「名前」「レベル」「ジョブ」となるようにせよ。
- `ex-02_2.sql` 👉 **w03.users** テーブルのすべてのレコードについて `id`、`name`、`age` を取得する SQL 文を記述し、実行せよ。なお、カラムは問題文に示した順序で並ぶようにし、それぞれのカラムのヘッダ (ラベル) が「出席番号」「名前」「年齢」となるようにせよ。

### SQLの文法上の注意

SQL では、`--` から行末までが **コメント** として扱われます。また、`/*` と `*/` で囲むと、複数行にわたるコメントを記述できます。説明を書き添えたり、SQL の一部を一時的に実行対象から外したりするときに使用します。VSCode では <span class="masked">`[Ctrl]+[/]`</span> のショートカットで、行コメントの設定と解除ができます。

SQL では、セミコロン `;` で **1つの文の終わり**を示します。演習でも、各 SQL 文の末尾にセミコロンを付けるようにしてください。実行環境によっては省略できる場合もありますが、<font color="deeppink"><b>本科目 (小テストや試験を含む) のなかでは必ずセミコロンを付けてください</b></font> (セミコロン抜けは誤答や減点とします)。

::: {.balloon .char-01 .face-05 .tone-blue}
PostgreSQL では、`SELECT` や `FROM` などの「**キーワード**」は、大文字と小文字を区別しません。例えば <span class="masked">`SELECT` と `select` </span>は同じ意味になります。

また、テーブル名やカラム名などの「**識別子**」は、**ダブルクォートで囲まなければ小文字として扱われます**。例えば、`users`、`USERS`、`Users` は、いずれも `users` というテーブル名として解釈されます。

一方、ダブルクォート `"` で囲んだ識別子は、**大文字と小文字が区別されます**。`"name"` は小文字の `name` カラムを参照しますが、`"Name"` は大文字の N で始まる別の名前です。今回の **w03.users** テーブルには `name` カラムがあり、`"Name"` カラムはないので、後者を参照するとエラーになります。
:::

::: {.note .type-tips}

**SQLの「文」と「句」について**

SQL では、セミコロンまでのひとまとまりを「**文**」、その文を構成する部分を「**句**」と呼びます。例えば、次の SQL 全体が「**SELECT文**」です。そのうち `SELECT id, name, age` が「**SELECT句**」、`FROM w03.users` が「**FROM句**」にあたります。

```sql{.numberLines caption="SQL: SELECT文"}
SELECT id, name, age FROM w03.users;
```

同様に、次の SQL 全体が「**INSERT文**」です。`INSERT INTO w03.users (id, name, age)` で挿入先のテーブルとカラムを指定し、`VALUES (1, 'Alice', 20), (2, 'Bob', 25)` という「**VALUES句**」で挿入するデータを指定しています。これは、**sql/03/init-users.sql** に記述した INSERT文と同じ内容を、スキーマ名を明示して書いた例です。

```sql{.numberLines caption="SQL: INSERT文"}
INSERT INTO
  w03.users (id, name, age)
VALUES
  (1, 'Alice', 20),
  (2, 'Bob', 25);
```

:::

#### 定着確認

- PostgreSQL の **w03.users** テーブルには `id`、`name`、`age` という名前のカラムが存在する。次の SQL 文を実行したところ構文エラー (Syntax Error) が発生した。SQL 文のどこに問題があるのかを説明せよ。
  - **答え**: <span class="masked">`FORM` は誤記であり、正しくは `FROM` である。</span>  
```sql{.numberLines caption="定着確認"}
SELECT id, name FORM w03.users;
```

- PostgreSQL の **w03.users** テーブルには `id`、`name`、`age` という名前のカラムが存在する。次の SQL 文を実行したところ構文エラー (Syntax Error) が発生した。SQL 文のどこに問題があるのかを説明せよ。
  - **答え**: <span class="masked">最後のカラム名 `age` のあとにあるカンマが不要である。</span>
```sql{.numberLines caption="定着確認"}
SELECT id, name, age, FROM w03.users;
```

- PostgreSQL において、スキーマ名 `w03`、テーブル名 `users`、カラム名 `id`、`name`、`age` が、すべて小文字で作成されている。次の SQL 文を実行した場合、問題なく実行できるか、それともエラーとなるか。理由とともに答えよ。
  - **答え**: <span class="masked">問題なく実行できる。キーワード (`SELECT` や `FROM`) は大文字と小文字を区別せず、ダブルクォートで囲んでいない識別子は小文字として扱われるため。</span>
```sql{.numberLines caption="定着確認"}
select NAME, AGE, ID FROM W03.Users;
```

- PostgreSQL において、スキーマ名 `w03`、テーブル名 `users`、カラム名 `id`、`name`、`age` が、すべて小文字で作成されている。次の SQL 文を実行した場合、問題なく実行できるか、それともエラーとなるか。理由とともに答えよ。
  - **答え**: <span class="masked">問題なく実行できる。ダブルクォートで囲まれた識別子が、大文字と小文字を含めて、実際のスキーマ名・テーブル名・カラム名と一致しているため。</span>  
```sql{.numberLines caption="定着確認"}
SELECT "name", "age" FROM "w03"."users";
```

- PostgreSQL において、スキーマ名 `w03`、テーブル名 `users`、カラム名 `id`、`name`、`age` が、すべて小文字で作成されている。次の SQL 文を実行した場合、問題なく実行できるか、それともエラーとなるか。理由とともに答えよ。
  - **答え**: <span class="masked">エラーとなる。ダブルクォートで囲まれた識別子は大文字と小文字が区別されるため、`"Name"` は `name` とは異なるカラム名として扱われる。`"Name"` という名前のカラムは存在しないため、`"name"` または `name` に修正する必要がある。</span>  
```sql{.numberLines caption="定着確認"}
SELECT "Name", age FROM w03.users;
```

- PostgreSQL の **w03.users** テーブルには `id`、`name`、`age` という名前のカラムが存在する。次の SQL 文を実行したところ、カラムに格納されている値ではなく、各行の値として「name」と「age」という文字列が出力された。この理由について説明せよ。
  - **答え**: <span class="masked">シングルクォートで囲んだ `'name'` と `'age'` は、カラム名ではなく文字列リテラルとして扱われるため。`SELECT name, age FROM w03.users;` もしくは `SELECT "name", "age" FROM w03.users;` とすることでカラムに格納されている値を出力できる。</span>
```sql{.numberLines caption="定着確認"}
SELECT 'name', 'age' FROM w03.users;
```

- PostgreSQL の **w03.users** テーブルには `id`、`name`、`age` という名前のカラムが存在する。次の SQL 文を実行したところ構文エラー (Syntax Error) が発生した。SQL 文のどこに問題があるのかを説明せよ。
  - **答え**: <span class="masked">エラーとなる。シングルクォートで囲まれた `'w03.users'` は「文字列リテラル」として扱われ、テーブル名として使用できない。正しくは `w03.users` または `"w03"."users"` と記述する。なお、`"w03.users"` と全体を囲むと、ドットを含む1つのテーブル名として解釈されるため、w03スキーマのusersテーブルを参照する指定にはならない。</span>
```sql{.numberLines caption="定着確認"}
SELECT * FROM 'w03.users';
```

### 定数値カラムを付加する

`SELECT` 文では、テーブルに格納されているカラムの値だけでなく、**数値や文字列などの定数値を取得結果のカラムとして出力すること** もできます。

例えば `w03.characters` テーブルの各レコードに対して、<span class="masked">すべてのレコードに共通する「リージョンID」や「ワールド名」などの情報を付加して表示したい場合など</span> に利用できます。

次の例では、数値の `8` と文字列の `'Zipangu'` を定数値として指定し、それぞれ「**RegionID**」「**World**」というカラムラベルを付けて出力しています。これらの値は、**<u>取得結果のすべての行に共通して表示されます</u>**。


```sql{.numberLines caption="定数値カラムを付加"}
SET
  search_path TO w03;

SELECT
  8 AS "RegionID", -- 定数値のカラム
  'Zipangu' AS "World", -- 定数値のカラム
  id AS "ID",
  name AS "名前"
FROM
  characters;
```

- **数値はクォートで囲まず**、**文字列はシングルクォート** `'` で囲んで記述することに注意してください。
- 本科目では、`AS` のあとのエイリアスを **ダブルクォート** `"` で囲む書き方を基本としていることに注意してください。

実際に実行して、以下のような結果セットが得られることを確認してください。

```
 RegionID |  World  | ID |  名前   
----------+---------+----+---------
        8 | Zipangu |  1 | Marvin
        8 | Zipangu |  2 | Zach
        8 | Zipangu |  3 | Charlie
        8 | Zipangu |  4 | Tom
        8 | Zipangu |  5 | Ivan
 ～～ 以下略 ～～       
```


::: {.balloon .char-01 .face-05 .tone-blue}
定数値カラムは `SELECT` 文の取得結果 (結果セット) に付加されるもので、**元のテーブルのカラム構成やデータはそのまま**です (影響を受けません)。
:::

::: {.note .type-tips}

**文字列とカラム名の書き分け**

`SELECT` 句では「**シングルクォート**」と「**ダブルクォート**」で囲んだものは、**それぞれ異なる意味を持ちます**。

- **シングルクォート**で囲んだ `'Zipangu'` は <span class="masked">文字列リテラル (固定値) </span> として扱われます。つまり「Zipangu」という文字列そのものが出力されます。
- **ダブルクォート**で囲んだ `"Zipangu"` は、<span class="masked">識別子 (カラム名など)</span> として扱われます。つまり「Zipangu」という名前のカラムを参照し、その値を取得して表示しようとします。
  - ただし、`w03.characters` テーブルには `Zipangu` のようなカラムが存在しないため、エラーとなります。

例えば、`'Zipangu' AS "World"` では、左側の `'Zipangu'` が **出力する文字列**、右側の `"World"` が **取得結果のカラムラベル (ヘッダ)** を指定するような意味となります。

:::

#### 定着確認

- SQL の `SELECT` 句で、文字列の定数値を指定するときは「シングルクォート」と「ダブルクォート」のどちらで囲むべきか答えよ。
  - **答え**: <span class="masked">シングルクォート。</span>

- SQL の `SELECT` 句において、`AS` につづけて記述するエイリアスを引用符で囲む場合、「シングルクォート」と「ダブルクォート」のどちらを使用すべきか答えよ。
  - **答え**: <span class="masked">ダブルクォート。</span>

- SQL の `SELECT` 句において `'Zipangu' AS "World"` は、どのような値を、どのようなカラムラベルで出力するか答えよ。
  - **答え**: <span class="masked">文字列「Zipangu」を、「World」というカラムラベルで出力する。</span>

- SQL の `SELECT` 句において、数値の定数値 8 を出力する記述として適切なものを選択せよ。
  - ❶ `8 AS "hoge",`
  - ❷ `'8' AS "hoge",`
  - ❸ `"8" AS "hoge",`
  - **答え**: <span class="masked">❶</span>

- PostgreSQL の **w03.users** テーブルに 2 件のレコードがあり、`name` の値はそれぞれ `Alice` と `Bob` である。`SELECT 'name' FROM w03.users;` を実行すると、各行にはどのような値が出力されるか答えよ。
  - **答え**: <span class="masked">どちらの行にも、文字列 name が出力される。</span>

- PostgreSQL の **w03.users** テーブルには 2 件のレコードがあり、`name` の値はそれぞれ `Alice` と `Bob` である。`SELECT name FROM w03.users;` を実行すると、どのような値が出力されるか答えよ。
  - **答え**: <span class="masked">name カラムに格納されている Alice と Bob が出力される。</span>

- PostgreSQL の **w03.characters** テーブルには、`Zipangu` というカラムが存在しない。`SELECT "Zipangu" FROM w03.characters;` は、問題なく実行できるか、エラーになるか答えよ。
  - **答え**: <span class="masked">エラーになる。"Zipangu" はカラム名として解釈されるが、その名前のカラムが存在しない。</span>

- PostgreSQL の **w03.users** テーブルには 2 件のレコードがあり、`name` カラムが存在する。`SELECT 4 AS "grade", 'M' AS "course", name FROM w03.users;` を実行すると、何行・何カラムの結果が得られるか答えよ。
  - **答え**: <span class="masked">2行・3カラム。</span>

- PostgreSQL の **w03.characters** テーブルに `RegionID` カラムは存在しない。`SELECT 8 AS "RegionID" FROM w03.characters;` を実行すると、元のテーブルに `RegionID` カラムが追加され、値 `8` が保存される。この説明は「適切である」か「適切ではない」か答えよ。
  - **答え**: <span class="masked">適切ではない。定数値カラムが付加されるのは取得結果であり、元のテーブルのカラム構成やデータは変わらない。</span>

#### SQLドリル💻

- `ex-03_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなチェックリストを出力する SQL 文を記述せよ。

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

- `ex-03_2.sql` 👉 **w03.users** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。

```
 grade | course | name  | age  
-------+--------+-------+------
     4 | M      | Alice | 20歳
     4 | M      | Bob   | 25歳
```

::: {.balloon .char-01 .face-05 .tone-blue}
上記の問題で `age` カラムの値について「**20歳**」のように表示するには、次のセクションで扱う「**文字列の結合**」を使用する必要があります。その解説を読んでから取り組んでください。
:::


### カラム値に文字列演算と算術演算を適用する

`SELECT` 句では、`||` 演算子を使って **文字列を結合 (連結)** することができます。カラムの値と文字列リテラルを組み合わせることで、「Marvin (Priest)」のような表示用の文字列をつくることができます。

次の例では「名前」と「ジョブ」の値を結合し、レベルには「Lv.」を付けて出力しています。

```sql{.numberLines caption="文字列演算の例"}
SET
  search_path TO w03;

SELECT
  name || ' (' || job || ')' AS "Name(Job)",
  'Lv.' || level AS "Level"
FROM
  characters;
```

実行結果は、次のようになります。

```
    Name(Job)     | Level 
------------------+-------
 Marvin (Priest)  | Lv.35
 Zach (Ninja)     | Lv.62
 Charlie (Wizard) | Lv.57
 Tom (Fighter)    | Lv.1
 Ivan (Monk)      | Lv.39
 ～～ 以下略 ～～
``` 

また、**数値型のカラム**については、加算や乗算などの <span class="masked">算術演算</span> を適用することができます。

次の例では、`buff` に `1` を加えて `100` 倍し、最後に `||` で「%」を付けています。例えば、`buff` が `-0.15` であれば「**85.00%**」、`0.10` であれば「**110.00%**」のように出力されるようにしています。

```sql{.numberLines caption="算術演算の例"}
SET
  search_path TO w03;

SELECT
  id AS "ID", 
  name AS "Name",
  buff AS "Buff",
  (buff + 1) * 100 || '%' AS "BuffApplied(%)"
FROM
  characters;
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
 ～～ 以下略 ～～
```

::: {.balloon .char-01 .face-02 .tone-yellow}


`ROUND(数値, 小数部の桁数)` を使うと、**NUMERIC 型の数値を指定した小数部の桁数で四捨五入** することができます。例えば、小数部の桁数に `0` を指定すると、小数第1位で四捨五入して整数値に丸めることができます。

例えば、`BuffApplied(%)` の値を「**85%**」や「**110%**」のように、**小数部のないパーセント表記**で出力するためには、次のように記述します。

```sql{.numberLines caption="ROUND() による四捨五入"}
SET
  search_path TO w03;

SELECT
  id AS "ID",
  name AS "Name",
  ROUND((buff + 1) * 100, 0) || '%' AS "BuffApplied(%)"
FROM
  characters;
```
:::

整数への切り上げには `CEIL()`、切り下げには `FLOOR()` という関数が使用できます。例えば、`CEIL(74.4)` は `75`、`FLOOR(74.4)` は `74` を返します。


::: {.balloon .char-01 .face-01 .tone-pink}

**負数** では、`CEIL(-1.2)` は <span class="masked">`-1`</span>、`FLOOR(-1.2)` は <span class="masked">`-2`</span> になる点にも注意してください。演算子や関数の詳細は、PostgreSQL 18 の公式ドキュメントで確認できます。

- 参考: 算術演算子 [Table 9.4. Mathematical Operators](https://www.postgresql.org/docs/18/functions-math.html#FUNCTIONS-MATH-OP-TABLE)
- 参考: 算術関数 [Table 9.5. Mathematical Functions](https://www.postgresql.org/docs/18/functions-math.html#FUNCTIONS-MATH-FUNC-TABLE)

:::

#### SQLドリル💻

- `ex-04_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。

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

- `ex-04_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。ただし、「Boosted Level」は `level` を `1.2` 倍して **整数に切り上げた値** とすること。

```
 id | Level | Boosted Level 
----+-------+---------------
  1 |    35 |            42
  2 |    62 |            75
  3 |    57 |            69
  4 |     1 |             2
  5 |    39 |            47
  ～～ 以下略 ～～
```

#### 定着確認

- PostgreSQL の **products** テーブルに、`value` という **NUMERIC型** のカラムがある。この値を **小数第 3 位** で四捨五入し、**小数第 2 位までの値** を取得したい。次の SQL の `????` に入る式を答えよ。
  - **答え**: <span class="masked">`ROUND(value, 2)`</span>  
  ```sql{.numberLines caption="定着確認"}
SELECT
    value,
    ???? AS "Rounded Value"
FROM
    products;
```

- PostgreSQL のあるテーブルに、`name` カラムの値が `Marvin`、`job` カラムの値が `Priest` であるレコードが存在する。  
このレコードに対して、`SELECT` 句に記述した `name || '(' || job || ')'` は、どのような文字列を出力するか答えよ。
  - **答え**: <span class="masked">`Marvin(Priest)`</span>

- PostgreSQL のあるテーブルに、NUMERIC 型の `buff` カラムの値が `-0.15` であるレコードが存在する。  
このレコードに対して、`SELECT` 句に記述した `ROUND((buff + 1) * 100, 0) || '%'` は、どのような文字列を出力するか答えよ。
  - **答え**: <span class="masked">`85%`</span>

- PostgreSQL において、`CEIL(-1.2)` と `FLOOR(-1.2)` は、それぞれどのような値を返すか答えよ。
  - **答え**: <span class="masked">`CEIL(-1.2)` は `-1`、`FLOOR(-1.2)` は `-2` を返す。</span>

### CASE 式を利用する

`SELECT` 句では、`CASE` 式を使って <span class="masked">条件に応じて異なる値を出力すること</span> ができます。

次の例では、**第08行目** から **第13行目** において **level** カラムの値に応じてキャラクタのクラスを「SS」「S」「A」「B」の4段階に分類しています。

```sql{.numberLines caption="CASE式による条件分岐のサンプル"}
SET
  search_path TO w03;

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
  characters;
```

::: {.balloon .char-01 .face-02 .tone-yellow}
`CASE` 式では、`WHEN` の条件が上から順に評価され、**最初に条件を満たした (`TRUE` となった)** `THEN` の値が出力されます。

どの条件も満たさない場合は `ELSE` の値が使われます。例えば、レベル `62` は「60以上」と「40以上」の両方を満たしますが、先に評価される「60以上」の条件によって「S」となります。

なお、`ELSE` を省略した場合、どの条件も満たさなければ `NULL` が出力されます。
:::

実行結果は、次のようになります。

```
 id |  name   | level | class 
----+---------+-------+-------
  1 | Marvin  |    35 | B
  2 | Zach    |    62 | S
  3 | Charlie |    57 | A
  4 | Tom     |     1 | B
  5 | Ivan    |    39 | B
  ～～ 以下略 ～～
```

::: {.balloon .char-01 .face-01 .tone-pink}

`WHEN` の条件式で「値が等しいこと」を比較するときは、`==` **ではなく** `=` **を使用してください** (間違いが多いので十分に注意してください)。一方で、「等しくないこと」を判定するには、標準 SQL の `<>` を使用してください。

- PostgreSQL では `!=` も使用できますが、本科目では標準 SQL に準拠した `<>` を基本とします。

また、複数の条件を組み合わせたいときは `AND` や `OR` が使用できます。
:::

**値が `NULL` かどうかを判定するには、`= NULL` ではなく `IS NULL` を使用してください**。

- PostgreSQL では、スペースを含めない `ISNULL` も使用できますが、本科目では標準 SQL に準拠した `IS NULL` を基本とします。

次の例では、ギルドが `NULL` のときだけ「**(無所属)**」を表示し、それ以外は `guild` の値をそのまま表示しています。

```sql{.numberLines caption="NULL判定の評価式"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  CASE
    WHEN guild IS NULL THEN '(無所属)' -- NULL判定には IS NULL を使用
    ELSE guild
  END AS "guild"
FROM
  characters;
```

:::{.note .type-caution}
**NULL との比較は十分に注意**

上記の **第08行目** において `guild = NULL` では、**guild** が **NULL** かどうかを正しく判定できません。

SQL では、通常の比較演算子 (`=`、`<>`、`<`、`>` など) を使って `NULL` との比較をおこなうと、その結果は `TRUE` でも `FALSE` でもなく、`UNKNOWN` となります。

PostgreSQL において、`UNKNOWN` に相当する状態は `NULL` として表現されます。これを 3値論理 (Three-Valued Logic) といい、詳しくは次回以降に解説します。
:::

実行結果は、以下のようになります。

```
 id |  name   |  guild   
----+---------+----------
  1 | Marvin  | Yamato
  2 | Zach    | D.D.D
  3 | Charlie | (無所属)
  4 | Tom     | (無所属)
  5 | Ivan    | (無所属)
  ～～ 以下略 ～～
```

#### 定着確認

- SQL の `SELECT` 句において、条件に応じて異なる値を出力するために使う式の名前を答えよ。
  - **答え**: <span class="masked">CASE式</span>

- PostgreSQL のあるテーブルに、`level` カラムの値が **62** のレコードが存在する。このレコードに対して、次の `CASE` 式はどのような値を返すか答えよ。
  - **答え**: <span class="masked">「S」。条件は上から順に評価され、最初に真となる `level >= 60` に対応する値が結果になる。</span>
```sql{.numberLines caption="定着確認"}
CASE
    WHEN level >= 80 THEN 'SS'
    WHEN level >= 60 THEN 'S'
    WHEN level >= 40 THEN 'A'
    ELSE 'B'
END
```

- PostgreSQL のあるテーブルに、`level` カラムの値が **62** のレコードが存在する。このレコードに対して、次の `CASE` 式はどのような値を返すか答えよ。
  - **答え**: <span class="masked">「A」。最初の `level >= 40` が真になるため、後続の `level >= 60` の条件には進まない。</span>
```sql{.numberLines caption="定着確認"}
CASE
    WHEN level >= 40 THEN 'A'
    WHEN level >= 60 THEN 'S'
    ELSE 'B'
END
```

- PostgreSQL のあるテーブルに、`level` カラムの値が **35** のレコードが存在する。このレコードに対して、次の `CASE` 式はどのような値を返すか答えよ。
  - **答え**: <span class="masked">「NULL」。条件を満たさず、ELSE も省略されているため。</span>
```sql{.numberLines caption="定着確認"}
CASE
    WHEN level >= 40 THEN 'A'
END
```

- 標準 SQL において、`job` カラムの値が文字列 `Fighter` と等しいかを比較したい。条件式 `job ???? 'Fighter'` の `????` に記述すべき演算子を答えよ。
  - **答え**: <span class="masked">`=`</span>

- 標準 SQL において、`job` カラムの値が文字列 `Fighter` と等しくないかを比較したい。条件式 `job ???? 'Fighter'` の `????` に記述すべき演算子を答えよ。
  - **答え**: <span class="masked">`<>`</span>

- SQL において、`level` が `50` 以上、かつ `created_on` が `2022-12-31` 以前という条件を記述したい。次の条件式の `????` に記述すべき語句を答えよ。
  - **答え**: <span class="masked">`AND`</span>
```sql{.numberLines caption="定着確認"}
level >= 50 ???? created_on <= DATE '2022-12-31'
```

- 標準 SQL において、`guild` カラムの値が `NULL` かどうかを判定したい。条件式 `guild ????` の `????` に記述すべき語句を答えよ。
  - **答え**: <span class="masked">`IS NULL`</span>

- PostgreSQL において、`guild` の値が `NULL` のとき、次の `CASE` 式はどのような値を返すか答えよ。
  - **答え**: <span class="masked">「所属あり」。`guild = NULL` の結果は UNKNOWN であり、TRUE にならないため、ELSE の値が使われる。NULL を判定するには `guild IS NULL` と記述する必要がある。</span>
```sql{.numberLines caption="定着確認"}
CASE
    WHEN guild = NULL THEN '(無所属)'
    ELSE '所属あり'
END
```

#### SQLドリル💻

- `ex-05_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。
  - `battle_position` は、`job` が「Fighter」「Samurai」「Monk」「Ninja」のいずれかであれば「frontline」、そうでなければ「backline」とすること。
  - frontline は前衛、backlineは後衛の意味。

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

---

- `ex-05_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。
  - `status` は、`buff` が `0` なら「--」、負数なら「debuff」、正数なら「buff」とすること。  

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

---

- `ex-05_3.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。`class` は、次の条件に従って決定すること。
  - **Master**: `level` が 50 以上、かつ `created_on` が 2022-12-31 以前。
  - **Veteran**: `Master` の条件を満たさず、`level` が 30 以上、かつ created_on が `2023-12-31` 以前。
  - **Rookie**: Master と Veteran のどちらの条件も満たさない。  

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

CASE式では、`guild` が `NULL` のときに「(無所属)」を表示しました。このような処理は、**COALESCE** (コアレス) を使うと、より簡潔に記述できます。

`COALESCE` は <span class="masked">引数のなかから、最初に見つかった `NULL` ではない値を返す関数</span> となります。引数を左から順に評価し、`NULL` ではない値が見つかった時点で、それを結果として返します。

たとえば、次のように書くと、**guild** の値が `NULL` の場合にだけ `(無所属)` が表示されるようになります。

```sql{.numberLines caption="COALESCE関数によるNULLの変換"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  guild,
  COALESCE(guild, '(無所属)') AS "所属"
FROM
  characters;
```

実行結果は、次のようになります。

```
 id |  name   | guild  |   所属   
----+---------+--------+----------
  1 | Marvin  | Yamato | Yamato
  2 | Zach    | D.D.D  | D.D.D
  3 | Charlie |        | (無所属)
  4 | Tom     |        | (無所属)
  5 | Ivan    |        | (無所属)
 ～～ 以下略 ～～
```

#### SQLドリル💻

- `ex-06_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。
  - `CASE` 式は使用せず、`COALESCE` を用いること。  
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

次の SQL を実行すると、**w03.characters** テーブルのすべてのレコードの `job` カラムの値を取得することができます。

```sql{.numberLines caption="jobカラムのみの出力"}
SET
  search_path TO w03;

SELECT
  job
FROM
  characters;
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

ここで、`SELECT` のあとに **DISTINCT** (ディスティンクト) キーワードを付けると、<span class="masked">取得結果の重複する行を1行にまとめること</span> ができます。この例では、同じジョブが複数回現れていても、結果には1回だけ表示されます。

```sql{.numberLines caption="DISTINCTによる重複の除外"}
SET
  search_path TO w03;

SELECT DISTINCT -- ◀◀ ここに注目
  job
FROM
  characters;
```

実行結果は以下のようになります。

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

::: {.balloon .char-01 .face-02 .tone-yellow}
複数のカラムを指定した場合は、**指定したカラムの値の組み合わせ**が同じ行を1行にまとめます。例えば、`SELECT DISTINCT job, guild` のようにギルドとジョブを取得する場合、ギルドが同じでもジョブが異なれば、それぞれの行が残ります。

実際に試してみてください。
:::

#### SQLドリル💻

- `ex-07_1.sql` 👉 **w03.characters** テーブルから、次に示すようなギルドの一覧を重複を除いて取得する SQL 文を記述せよ。出力する行の順番は問わない。

```
 ギルド 
--------
 未所属
 Yamato
 hameln
 D.D.D
```

- `ex-07_2.sql` 👉 **w03.characters** テーブルから、次に示すようにギルドとジョブの組み合わせを重複を除いて取得する SQL 文を記述せよ。出力する行の順番は問わない。

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

### 日付・時刻関数を利用する

TIMESTAMP型の値から、「年」「月」「日」「時」「分」「秒」を 算術演算可能な **数値** として取り出すには、`DATE_PART` 関数を使用します。

次の例では、**w03.characters** を対象に「**最終ログイン日時** (TIMESTAMP 型)」を、それぞれの要素に分けて出力しています。なお `last_login_at` が `NULL` のレコードでは、取り出した値は、一律で `NULL` となります。

```sql{.numberLines caption="日付と時刻の分解"}
SET
  search_path TO w03;

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
  characters;
```

- `DATE_PART` 関数は、標準 SQL には存在しません。PostgreSQL 固有の関数です。
- `DATE_PART` 関数は、`TIMESTAMP` 型だけではなく `DATE` 型のデータから「年」「月」「日」を取得する場合にも使用できます。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL の DATE_PART で、TIMESTAMP型の last_login_at から年・月・日・時・分・秒を取り出す方法を学びました。標準 SQL では、どのようにしますか。実行可能な SQL のサンプルを示し、DATE_PART との構文や戻り値の型の違いも説明してください。

---

TIMESTAMP 型の値を指定した書式で整形した文字列に変換するには、`TO_CHAR` を使用します。DATE型にも利用できます。

次の例では、最終ログイン日時を「**2025/07/24 13時31分00秒**」のような整形文字列に変換して出力しています。

```sql{.numberLines caption="日時のフォーマット(文字列整形)"}
SET
  search_path TO w03;

SELECT
  name,
  last_login_at,
  TO_CHAR(last_login_at, 'YYYY"/"MM"/"DD HH24"時"MI"分"SS"秒"')
FROM
  characters;
```

`TO_CHAR` の 第2引数 に与える `YYYY` や `MI` などは「**フォーマット指定子**」です。例えば、`YYYY` は4桁の年、`MM` は月、`MI` は分、`HH24` は24時間表記の時を表します。使用できる指定子については、以下の公式ドキュメントを参照してください。

- [Table 9.27. Template Patterns for Date/Time Formatting](https://www.postgresql.org/docs/18/functions-formatting.html#FUNCTIONS-FORMATTING-DATETIME-TABLE)


::: {.balloon .char-01 .face-02 .tone-yellow}
`TO_CHAR` 関数では、**書式指定子として解釈させず、そのまま出力したい文字列をダブルクォートで囲みます**。

上記の **第07行目** の `TO_CHAR` 関数の「第2引数」では、書式全体を **シングルクォート** で囲み、その内側で「時」「分」「秒」などの文字列を **ダブルクォート** で囲んでいる点に注目してください。
:::

#### 定着確認

- PostgreSQL において、TIMESTAMP 型の `last_login_at` の値が `2025-07-24 13:31:00` となっている。`DATE_PART('month', last_login_at)` は、どのような値を返すか答えよ。
  - **答え**: <span class="masked">数値の `7`。</span>

- PostgreSQL において、TIMESTAMP 型の `last_login_at` の値が `2025-07-24 13:31:00` となっている。`DATE_PART('minute', last_login_at)` は、どのような値を返すか答えよ。
  - **答え**: <span class="masked">数値の `31`。</span>

- PostgreSQL において、TIMESTAMP 型の `last_login_at` の値が `NULL` である。`DATE_PART('year', last_login_at)` はどのような値を返すか答えよ。
  - **答え**: <span class="masked">`NULL`。</span>

- PostgreSQL において、TIMESTAMP 型の `last_login_at` の値が `2025-07-24 13:31:00` である。次の式は、どのような文字列を返すか答えよ。
  - **答え**: <span class="masked">`2025/07/24 13時31分00秒`</span>
```sql{.numberLines caption="定着確認"}
TO_CHAR(last_login_at, 'YYYY"/"MM"/"DD HH24"時"MI"分"SS"秒"')
```

- PostgreSQL の `TO_CHAR` 関数を使用して日時を文字列に変換するとき、フォーマット指定子 `MM` と `MI` は、それぞれ何を表すか答えよ。
  - **答え**: <span class="masked">`MM` は月、`MI` は分。どちらも2桁で表示され、1桁の値は先頭に0を付けてゼロ埋めされる。例えば、7月は `07`、5分は `05` と表示される。</span>

- PostgreSQL の `TO_CHAR` 関数を使用して日時を文字列に変換するとき、24時間表記 (ゼロ埋め2桁) の「時」を指定するフォーマット指定子を答えよ。
  - **答え**: <span class="masked">`HH24`</span>

#### SQLドリル💻

- `ex-08_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、以下に示す形式で各カラムを出力する SQL 文を記述せよ。なお、`created_on` の値はすべて `2020-09-01` 以降であり、「平成」や「元禄」など令和以外の元号への対応は不要とする。
  - **ヒント**: 和暦 (令和) の年は、西暦から <span class="masked">`2018`</span> を減じることで求められる。

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

- `ex-08_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、`last_login_at` から次に示すようなカラムを出力する SQL 文を記述せよ。
  - 数値の取得には `DATE_PART`、文字列の取得には `TO_CHAR` を使用すること。

```
 id |  name  | 月(数値)  | 月(文字列)  | 分(数値)  | 分(文字列)
----+--------+----------+------------+----------+-----------
  1 | Marvin |        7 | 07         |       31 | 31
  4 | Tom    |          |            |          |
 12 | Dave   |        8 | 08         |        8 | 08
```

上記の実行結果は、部分的に抜粋したものです。

### 現在日時と日数・時間の差を計算する

**現在の日付や時刻** を取得するためには、次の「日時値関数」を使用します。

- **日時**: `LOCALTIMESTAMP` は **TIMESTAMP** 型、`CURRENT_TIMESTAMP` は **TIMESTAMP<u>TZ</u>** 型の値を返します。
- **時刻**: `LOCALTIME` は **TIME** 型、`CURRENT_TIME` は **TIME<u>TZ</u>** 型の値を返します。
- **日付**: `CURRENT_DATE` は、時刻を含まない **DATE** 型の値を返します。

::: {.balloon .char-01 .face-01 .tone-pink}
PostgreSQL では、日時値関数が返す値の基準は **現在のトランザクションの開始時点**です。同じトランザクション内では、処理が進んでも値は変わりません。また、日付や時刻は、現在のセッションに設定されているタイムゾーンに基づきます。
:::

```sql{.numberLines caption="日時値関数から得られる値の動作確認"}
SELECT
  LOCALTIMESTAMP AS "LOCALTIMESTAMP",
  CURRENT_TIMESTAMP AS "CURRENT_TIMESTAMP";

SELECT
  LOCALTIME AS "LOCALTIME",
  CURRENT_TIME AS "CURRENT_TIME";

SELECT
  CURRENT_DATE AS "CURRENT_DATE";
```

```sql{.numberLines caption="日時値関数から得られる値の型確認"}
SELECT
  pg_typeof(LOCALTIMESTAMP) AS "LOCALTIMESTAMP",
  pg_typeof(CURRENT_TIMESTAMP) AS "CURRENT_TIMESTAMP";

SELECT
  pg_typeof(LOCALTIME) AS "LOCALTIME",
  pg_typeof(CURRENT_TIME) AS "CURRENT_TIME";

SELECT
  pg_typeof(CURRENT_DATE) AS "CURRENT_DATE";
```

**w03.characters** テーブルでは、`created_on` は DATE型、`last_login_at` はタイムゾーン情報を含まない TIMESTAMP 型でカラムが定義されています。このため、日付同士の差を求めるときは `CURRENT_DATE`、日時同士の差を求めるときは `LOCALTIMESTAMP` を使うと、カラムと同じ型で計算ができます。

- TIMESTAMPTZ型のカラムと現在日時の差を求める場合は、`CURRENT_TIMESTAMP` を使うと同じ型で計算できます。

::: {.note .type-senior}

**datetime value function (日時値関数) について**

`LOCALTIMESTAMP`、`CURRENT_DATE`、`LOCALTIME` などは、**datetime value function (日時値関数)** と呼ばれ、現在の日付や時刻を取得するために使用します。これらは一般的な関数とは異なり、**通常は括弧を付けずに記述します**。

ただし、時刻や日時を返す関数では、`LOCALTIME(0)` や `LOCALTIMESTAMP(3)` のように、括弧内に **秒の小数部の桁数 (精度)** を指定できます。例えば、`0` を指定すると秒単位、`3` を指定するとミリ秒単位の値となります。なお、指定した精度に応じて秒の小数部は四捨五入されます。

```sql{.numberLines caption="日時値関数の動作確認"}
SELECT
  LOCALTIME AS "LOCALTIME",
  LOCALTIME(0) AS "LOCALTIME(0)",
  LOCALTIME(3) AS "LOCALTIME(3)";

SELECT
  LOCALTIMESTAMP AS "LOCALTIMESTAMP",
  LOCALTIMESTAMP(0) AS "LOCALTIMESTAMP(0)",
  LOCALTIMESTAMP(3) AS "LOCALTIMESTAMP(3)";
```

注意点として、PostgreSQL では `LOCALTIME()` のように **空の括弧を付けると構文エラー**になります。また、`CURRENT_DATE` は日付のみを返すため、精度を指定することはできません。

:::

::: {.note .type-senior}

**タイムゾーン情報の扱いについて**

日時を「どの地域での時刻」として扱うかは、**DB に接続するアプリケーションの設計や表示にも関わります**。TIMESTAMP型の値を異なる地域のローカル時刻として解釈すると、同じ値から異なる時点を指すことになります。

TIMESTAMPTZ型では同じ時点を保存できますが、表示する時刻はセッションのタイムゾーンによって変わります。保存する型と、表示時に使うタイムゾーンの両方を意識してください。
:::

例えば、キャラクタ作成日 (`created_on`) から今日までの日数を求めるには、`CURRENT_DATE - created_on` と記述します。**DATE型同士の減算** (`DATE - DATE`) の結果は <span class="masked">整数型の日数差</span> になります。

```sql{.numberLines caption="登録日からの経過日数の取得"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  created_on,
  CURRENT_DATE - created_on AS "Days Since Created"
FROM
  characters;
```

最終ログイン日時 (`last_login_at`) から現在日時までの経過時間を求めるには、`LOCALTIMESTAMP - last_login_at` と記述します。**TIMESTAMP型同士の減算** (`TIMESTAMP - TIMESTAMP`) の結果は、時間の隔たりを表す **INTERVAL型** になります。`last_login_at` が `NULL` なら、計算結果も `NULL` です。

```sql{.numberLines caption="最終ログインからの経過時間"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  last_login_at,
  LOCALTIMESTAMP - last_login_at AS "Elapsed Time Since Last Login"
FROM
  characters;
```

INTERVAL型にも、`DATE_PART` や `TO_CHAR` を使えます。例えば、`DATE_PART('day', interval型の値)` では、その値の日の部分を取り出せます。

---

TIMESTAMP型の値から日付だけを取り出すには、次のように **DATE型にキャスト (型変換)** します。

```sql{.numberLines caption="TIMESTAMPをDATEに変換"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  last_login_at,
  CAST(last_login_at AS DATE) AS "last_login_at(DATE型)"
FROM
  characters;
```

- PostgreSQL では `CAST(last_login_at AS DATE)` を <span class="masked">`last_login_at::DATE`</span> のように記述することができます (標準SQL構文ではない)。 

固定の日付や日時を計算に使うときは、`CAST('2025-04-01' AS DATE)` や `CAST('2025-04-01 13:05:59' AS TIMESTAMP)` のように、文字列を目的の型に変換できます。標準 SQL では、`DATE '2025-04-01'` や `TIMESTAMP '2025-04-01 13:05:59'` として型を明示したリテラルを書くこともできます。

次の例では、固定の基準日 `2026-03-31` と今日の日付との差を求めています。実行日が基準日より前なら正の値、同じ日なら `0`、後なら負の値になります。

```sql{.numberLines caption="固定の基準日と今日の日付との差"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  (CAST('2026-03-31' AS DATE) - CURRENT_DATE) || '日' AS "基準日までの日数"
FROM
  users;
```

#### SQLドリル💻

- `ex-09_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。「最終ログイン」は `2025-10-15` を基準日とし、日付同士の差で計算すること。

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

- `ex-09_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL 文を記述せよ。ただし、**Days Since Last Login** は、基準日を `2025-10-15` とし、日付同士の差で計算すること。「Is Active User?」は、最終ログインからの日数が `50` 以下なら「Yes」、それ以外は「No」とすること。

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

- PostgreSQL で、現在のトランザクション開始時点の日時を、タイムゾーン情報を含まない TIMESTAMP型で取得したい。標準 SQL のどの日時値関数を使えばよいか答えよ。
  - **答え**: <span class="masked">`LOCALTIMESTAMP`</span>
- PostgreSQL で、現在のトランザクション開始時点の日付を DATE型で取得したい。標準 SQL のどの日時値関数を使えばよいか答えよ。
  - **答え**: <span class="masked">`CURRENT_DATE`</span>

- PostgreSQL の `CURRENT_TIMESTAMP` が返す値のデータ型を答えよ。
  - **答え**: <span class="masked">TIMESTAMPTZ型 (TIMESTAMP WITH TIME ZONE)。</span>

- PostgreSQL で、現在の時刻をタイムゾーン情報を含まない TIME型で取得したい。標準 SQL のどの日時値関数を使えばよいか答えよ。
  - **答え**: <span class="masked">`LOCALTIME`</span>

- PostgreSQL で、同じトランザクション内で `LOCALTIMESTAMP` を複数回参照した。処理に時間がかかっていても、返される日時は同じか、それとも参照するたびに変わるか。理由とともに答えよ。
  - **答え**: <span class="masked">同じ。LOCALTIMESTAMPは、現在のトランザクションの開始時点を基準とするため。</span>

- PostgreSQL で `SELECT LOCALTIME();` を実行すると、構文エラーが発生する。現在の時刻を取得するためには、どのように修正すればよいか答えよ。
  - **答え**: <span class="masked">空の括弧を外し、`SELECT LOCALTIME;` とする。秒の小数部の桁数を指定する場合は、`SELECT LOCALTIME(0);` などと記述する。</span>

- PostgreSQL で、DATE型の値同士を減算した結果のデータ型と、その値が表す単位を答えよ。
  - **答え**: <span class="masked">INTEGER型で、日数差を表す。</span>

- PostgreSQL で、TIMESTAMP型の値同士を減算した結果のデータ型を答えよ。
  - **答え**: <span class="masked">INTERVAL型。</span>

- PostgreSQL で、TIMESTAMP型の `last_login_at` の値が `2025-07-24 13:31:00` である。`CAST(last_login_at AS DATE)` の結果を答えよ。
  - **答え**: <span class="masked">DATE型の値 `2025-07-24`。時刻の部分は含まれない。</span>

- PostgreSQL で、`CAST(last_login_at AS DATE)` と同じ型変換を、`::` を使って記述せよ。
  - **答え**: <span class="masked">`last_login_at::DATE`</span>

- PostgreSQL で、`DATE '2025-10-15' - DATE '2025-10-01'` の結果を答えよ。
  - **答え**: <span class="masked">整数の `14`。</span>

- PostgreSQL で、TIMESTAMP型の `last_login_at` の値が `NULL` である。`LOCALTIMESTAMP - last_login_at` の結果を答えよ。
  - **答え**: <span class="masked">`NULL`。</span>

## 授業時間外学習の指示 (宿題)

🚨**本科目は「学修単位科目」であり、1回の講義あたり「4時間相当」の授業時間外学習が求められる科目です**🏃

- 次回の講義で「**小テスト❸**」を実施します。
  - **定着確認** および **SQLドリル** から主に出題します。
  - 講義が進行するにつれて、当然ながら小テストの内容も複雑で高度なものになっていきます。前半で、しっかりと得点をとるようにしてください。

---

- この講義資料を再読・熟読し「不明な用語」や「理解が不十分な用語」があればインターネットや、ChatGPTなどの生成AIを利用して解決してください。また、興味関心を持ったトピックについて、ウェブ、生成AI、YouTube動画などを利用して知識を広げ、理解を深めてください。
  - 特に **<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例** を示しているものについては、実際に生成AIにプロンプトを投げ、さらに対話を重ねることで、知識の幅を広げるだけでなく、理解をより深く確かなものにしてください。
- 講義資料内の「**演習**」や「**SQLドリル**」に再度取り組んでください。特に、**SQLドリル**💻 は、授業時間中に1回取り組むだけでは定着しないので注意してください。
