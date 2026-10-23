---
var:
  header-title: "2026-4I データベース工学 第05回 講義資料"
  header-date: "2026年10月28日 (水) 1時限"
---

# 第05回 4I-データベース工学

## 連絡

- 小テスト➍ を実施します。
  - シラバス記載のように、小テストは最終評価の <span class="masked">35\%</span> に相当します。 
  - 遅刻・欠席等により追試験を希望する場合は [第01回講義で案内した手続き](lecture01.html#成績評価法と履修上の注意) をしてください。

- 今回の講義内容は、[前回講義](lecture04.html)の内容を**ひととおり理解していること**を前提とします。まだ、前回の内容 (授業時間外学習のセクションを含む) を終えていない人は、まずは、そちらから取り組んでください。

### 今回の達成目標

- トランザクションの役割を説明し、`COMMIT` による確定と `ROLLBACK` による取消しを実行・確認できる。
- CSV ファイルをコンテナに配置し、`COPY` によるレコードの一括挿入を実行できる。
- `WHERE` 句で対象を指定してレコードを更新・削除し、変更前後とロールバック後の状態を確認できる。
- `COUNT`、`SUM`、`AVG`、`MAX`、`MIN` を使用して集計し、`NULL` の扱いを説明できる。
- `GROUP BY` でグループごとに集計し、`WHERE` と `HAVING` の役割を区別して条件を指定できる。

## 準備と前回の復習

### ハンズオン学習の準備

次の手順でSQL演習環境の立ち上げと、教材の更新を取得してください。

- [SQL演習環境の動作確認](lecture04.html#sql演習環境の動作確認-前回復習)@ 第04回講義
- [教材の更新の取得](lecture04.html#教材の更新の取得)@ 第04回講義

今回も、第03回・第04回と同じ **w03.users** と **w03.characters** テーブルを使用します。教材の更新後は、**from-teacher/05** に CSV ファイルと SQL ドリルの解答例があることを確認してください。

::: {.balloon .char-01 .face-02 .tone-yellow}
今回も、SQL ファイルごとに先頭で `SET search_path TO w03;` を実行してください。これにより、そのファイル内では **w03.users** を **users**、**w03.characters** を **characters** と記述できます。設定は別の SQL ファイルには引き継がれません。
:::

演習用の SQL ファイルは **sql/05** に作成してください。SQL ドリルの解答例は **from-teacher/05/drill** にあります。以下の実行結果は、先頭の `SET` の応答などを省略して掲載しています。

SQL ドリルは、特に指定がない限り、**w03.characters が第03回の初期データ19件であること**を前提とします。更新・削除の問題は、`START TRANSACTION` ～ `ROLLBACK` の範囲内で実行し、対象のカラムや件数を変更前後に確認してください。ロールバック後も、元の状態に戻ったことを確認してください。

### 前回の復習

前回の講義では `SELECT` 文における `ORDER BY` 句、`LIMIT` 句、`OFFSET` 句、`WHERE` 句について学びました。

- `ORDER BY` は、レコードの **整列順 (ソート順) を指定する** ための句でした。
- `LIMIT` は、取得するレコードの **件数を制限する** ための句でした。
- `OFFSET` は、レコードの **取得開始位置を調整する (スキップする)** ための句でした。
- `WHERE` は、**抽出条件を指定する** ための句でした。

これらを組み合わせることで、テーブルから「どのレコードを」「どの順で」「どの位置から」「何件だけ」取り出すかを柔軟に制御できるようになりました。

::: {.note .type-tips}
**補足： `WHERE` の意味**

SQL における `WHERE` は疑問詞としての「**どこ？**」ではなく、「**〜という場所 (〜であるような行)**」という関係副詞的な用法で使われています。つまり、`WHERE` 句は「**〜という条件に該当する行を選ぶ**」という指示になります。

- I came from Japan, **where** I was born and raised.

:::

また、前回講義では、テーブルにレコードを <span class="masked">挿入する</span> ための基本的な `INSERT` 文と、**その動作/挙動を安全に確認するため** の **_トランザクション_** (`START TRANSACTION` ～ `ROLLBACK`) についても学びました。

## トランザクション

RDBMS において、**トランザクション** (**Transaction**) とは、データの一貫性や整合性を保つために <span class="masked">論理的にまとめて実行されるべき一連の操作や処理のかたまり</span> を意味します。そして、RDBMS では、トランザクションに対して...

- **すべての処理を「成功」として確定させる** 👉 **_コミット_**
- **すべての処理を「失敗」として操作を取り消して元に戻す** 👉 **_ロールバック_**

...の「**いずれかの結果のみ**」を保証します。

例えば、トランザクションのなかに `SQL-1`、`SQL-2`、`SQL-3` という3つの SQL 文が含まれているとき...

- `SQL-1` と `SQL-2` は**成功**し、`SQL-3` は**失敗**した

...といった **中途半端な結果が生じないように保証** する機能を持ちます。具体的には `SQL-3` が失敗した時点で、RDBMS は `SQL-1` と `SQL-2` の操作を無効にし、データベースを <span class="masked">トランザクション開始前の状態</span> に戻します。

### トランザクションが必要とされる理由 (銀行送金の例)

一般に、トランザクションは次のような場面で非常に強力に機能します。

> 預金管理 DB において Alice から Bob に 10,000 円を移す

この送金処理は、実際には次のような **2つの操作から構成** されます。

1. Alice の口座残高から 10,000 円を減算する
2. Bob の口座残高に 10,000円 を加算する

この 2 つの操作は、**どちらか一方だけが成功しても正しい状態とはいえません**。Alice の残高だけが減って Bob に振り込まれなければ「お金が消える」ことになってしまい、逆に Bob だけに入金されて Alice の残高が減らなければ「お金が増える」ことになってしまい、いずれも不整合な状態となります。

そこで RDBMS では、これらの2つの操作を「ひとつのトランザクション」としてまとめて扱うことで、途中でどちらかの操作が失敗した場合には、**_ロールバック_** により <span class="masked">全ての操作を取り消して元の状態に戻す</span> ことで、データの整合性 (一貫性) を保つ仕組みを提供しています。逆に、すべての操作が正常に完了したときにのみ **_コミット_** により処理を確定する仕組みを提供しています。


### トランザクションの使用例

ここでは **w03.users** テーブルを使用して「トランザクションの基本的な使い方」を確認していきます。まずは、次のコマンドで **w03.users** テーブルを初期化してください。**既存のデータも削除され、Alice と Bob の2件に戻ります**。

```bash
npm run sql from-teacher/03/init-users.sql
```

現在、このテーブルには、Alice と Bob の2件のレコードが含まれます。この状態から、トランザクションを使って 3 件のレコードを挿入していきます。**sql/05/tmp.sql** などの適当なファイルを作成して、以下の SQL を貼り付けて実行してください。

```sql{.numberLines caption="トランザクション～全成功してコミットされる例～"}
SET
  search_path TO w03;

-- トランザクションの開始
START TRANSACTION;

-- 操作1 Carol の登録 (成功)
INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18);

-- 操作2 Dave の登録 (成功)
INSERT INTO
  users (id, name, age)
VALUES
  (4, 'Dave', NULL);

-- 操作3 Ellen の登録 (成功)
INSERT INTO
  users (id, name, age)
VALUES
  (5, 'Ellen', 17);

-- START TRANSACTION 以降の全ての操作が成功していれば「確定」
COMMIT;

-- テーブルの状態を確認
SELECT * FROM users ORDER BY id;
```

この例では、`START TRANSACTION` から `COMMIT` までに含まれるすべての操作 (操作1から操作3) が正常完了するため、**第26行目** の `COMMIT` によって処理が確定され、結果がテーブルに反映されます。コンソールには、**第29行目** によって次のような結果が出力されるはずです。

```
START TRANSACTION
INSERT 0 1
INSERT 0 1
INSERT 0 1
COMMIT
 id | name  | age
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
  3 | Carol |  18
  4 | Dave  |
  5 | Ellen |  17
(5 行)
```

ここで、上記の **第2行目** から **第4行目** の `INSERT 0 1` は <span class="masked">各操作で1件のレコードが挿入されたこと</span> を表す応答です。`0` は、 OID (Object Identifier) を表しています。気になる人は生成AIを使って調べてください。

- 厳密には、挿入先テーブルが OID を持つなら OID、そうでなければ `0` の応答を持ちます。

::: prompts
- PostgreSQL 17 で、テーブルに1件のレコードを挿入したとき、`INSERT 0 1` のような応答が返ってきます。ここでの `0` は、どのような意味ですか。
:::

---

つづいて、**トランザクションの途中で失敗が発生する例** を確認していきます。まずは、再度、次のコマンドで **w03.users** テーブルの内容を初期化してください (レコードを2件に戻しておきます)。

```bash
npm run sql from-teacher/03/init-users.sql
```

以下の SQL を貼り付けて実行してください。このコードでは **第20行目** からの `INSERT` 文に **id** の重複があり、「**操作3**」が失敗する (＝エラーが発生する) ようになっています。

```sql{.numberLines caption="トランザクション～失敗によるロールバック例～"}
SET
  search_path TO w03;

-- トランザクションの開始
START TRANSACTION;

-- 操作1 Carol の登録 (成功)
INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18);

-- 操作2 Dave の登録 (成功)
INSERT INTO
  users (id, name, age)
VALUES
  (4, 'Dave', NULL);

-- 操作3 Ellen の登録 (❌失敗 id=4 が重複) 
INSERT INTO
  users (id, name, age)
VALUES
  (4, 'Ellen', 17);

-- START TRANSACTION 以降の全ての操作が成功していれば「確定」
COMMIT;

-- テーブルの状態を確認
SELECT * FROM users ORDER BY id;
```

実行結果は、次のようになります。

```
psql:<stdin>:23: ERROR:  重複したキー値は一意性制約"users_pkey"違反となります
DETAIL:  キー (id)=(4) はすでに存在します。
```

ここで注目してほしいのは、「操作1」と「操作2」についての <span class="masked">`INSERT 0 1` という応答が表示されていないこと</span>、そして、トランザクション終了後に記述された **第29行目** の `SELECT` 文も**実行されていないこと**です。

この状態で、別途 `SELECT * FROM w03.users ORDER BY id;` を単独で実行すると、次のような結果 (＝<span class="masked">トランザクション開始前の状態</span>) が得られます。

```
 id | name  | age 
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
(2 行)
```

以上のように、トランザクションのなかでエラーが発生すると、**トランザクションのなかの全ての操作が取り消され、トランザクションの開始前の状態に戻ること** (＝ロールバックされること) が確認できました。

### 明示的なロールバック

`START TRANSACTION` ～ `COMMIT` において、`COMMIT` の代わりに <span class="masked">`ROLLBACK`</span> を記述すると明示的に **ロールバック** をかけることができます。

```sql{.numberLines caption="明示的なロールバックの実行"}
SET
  search_path TO w03;

-- トランザクションの開始
START TRANSACTION;

INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18);

-- テーブルの状態を確認 👉 Carol のレコードが存在する
SELECT * FROM users ORDER BY id;

-- 明示的にロールバックを実行
ROLLBACK;

-- テーブルの状態を確認 👉 Carol のレコードが存在しない
SELECT * FROM users ORDER BY id;
```

::: {.note .type-caution}
**注意**

以下、演習のなかで `UPDATE` 文や `DELETE` 文を扱いますが、特に指示のないかぎりは「`START TRANSACTION` ～ `ROLLBACK`」の内部で処理を実行するようにしてください。 
:::

#### 定着確認

- PostgreSQL において、トランザクションを開始する際に使用する SQL キーワード (2語) を答えよ。大文字で答えること。
  - **答え** : <span class="masked">`START TRANSACTION`</span>
- PostgreSQL において、トランザクションを取り消す (元に戻す) 際に使用する SQL キーワードを答えよ。大文字で答えること。
  - **答え** : <span class="masked">`ROLLBACK`</span>
- PostgreSQL において、トランザクション内の処理を確定する際に使用する SQL キーワードを答えよ。大文字で答えること。
  - **答え** : <span class="masked">`COMMIT`</span>


- **w03.users** には Alice と Bob の2件だけが登録されている。トランザクションを開始し、Carol を1件挿入した。同じ接続で、`ROLLBACK` の直前と直後に `SELECT COUNT(*) FROM w03.users;` を実行したとき、それぞれ何件になるか答えよ。
  - **答え**: <span class="masked">直前は3件、直後は2件。</span>

- **w03.users** に対してトランザクションを開始し、Carol を1件挿入して `COMMIT` した。その後、新しいトランザクションを開始して、データを変更せずに `ROLLBACK` した。先に挿入した Carol のレコードは取り消されるか答えよ。
  - **答え**: <span class="masked">取り消されない。先のCOMMITで確定した変更は、後から開始したトランザクションのROLLBACKでは取り消されない。</span>

- Alice から Bob に送金するため、「Alice の残高を減らすUPDATE」と「Bob の残高を増やすUPDATE」を実行する。これらを1つのトランザクションに含める理由を説明せよ。
  - **答え**: <span class="masked">片方だけが確定することを防ぎ、両方を確定するか、両方とも取り消すことで残高の整合性を保つため。</span>

## CSVファイルからのINSERT 

[前回講義](lecture04.html#insert文-超基礎編)では `INSERT` 文を使って「テーブルに 1 件ずつレコードを挿入する方法」を紹介しました。しかし、実務では、**数十件から数千件といった大量データを扱うことが多く**、そのようなときは「**CSVファイル**」を使ってデータを一括挿入することが一般的となります。

ここでは、CSVファイルを使ってデータを一括挿入する手順について説明します。

### CSV ファイルの作成

テーブルにデータを挿入するための「CSVファイル」を作成します。ここでは、**w03.users** テーブル用に予め用意した `from-teacher/05/insert-users.csv` (最新の教材の更新に含まれています) を使用します。

VSCode から `insert-users.csv` を開いて内容を確認してください。

なお、PostgreSQL に挿入するための CSV ファイルを作成する際は、**文字コード**を <span class="masked">BOMなしのUTF-8</span>、**改行コード**を「**LF**」に設定しておくことが推奨されます。

::: prompts
- UTF-8の「BOM付き」と「BOMなし」の違いについて教えてください。「BOM付き」が利用される場面としてはどのようなものがありますか。
:::

### CSV ファイルをコンテナに配置

`insert-users.csv` は、ホストOS (Windows) 上に存在するため、**Docker コンテナ内で動作している PostgreSQL からは直接取り込むことができません**。

そのため、まずこの CSV ファイルをコンテナの `/tmp/` にコピーします。VSCode のターミナルから次のコマンドを実行してください。コマンドのなかの `pg18` は<i class="fa-brands fa-github"></i>[docker/docker-compose.yaml](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/docker/docker-compose.yaml)の **第04行目** で指定している PostgreSQL コンテナの「名前」になります。

```bash
docker cp from-teacher/05/insert-users.csv pg18:/tmp/
```

ファイルのコピーに成功すると、次のようなメッセージが返ってきます。

```
Successfully copied 46B (transferred 2.05kB) to pg18:/tmp/
```

コピーが完了したら、実際にコンテナのなかにCSVファイルが配置されたことを確認していきます。[第02回講義](lecture02.html#コンテナの利用-bash経由) で紹介したように `docker container exec -it pg18 bash` コマンドを使ってコンテナに接続してもよいですが、ここでは <span class="masked">Docker Desktop</span> から確認する方法を紹介しておきます。

Docker Desktop のウィンドウで「**Containers**」を選択し、さらに「**pg18**」の三点リーダ <i class="fa-solid fa-ellipsis-vertical"></i> から「**Open in terminal**」を選択してください。

![img](figs/05/docker-01.png)

これで、コンテナの **bash** に接続した状態になります。`ls -al /tmp` のコマンドで、コンテナ内の `/tmp` に CSV ファイルがあることを確認してください。

![img](figs/05/docker-02.png)

### CSV ファイルからテーブルに取り込み

PostgreSQL では、以下のような SQL により、**CSV ファイルからレコードを一括でテーブルに取り込むこと**ができます。

実行前に、次のコマンドで **w03.users** を Alice と Bob の2件に戻してください。**既存のデータも初期状態に戻ります**。

```bash
npm run sql from-teacher/03/init-users.sql
```

```sql{.numberLines caption="CSVファイルからレコードを挿入"}
SET
  search_path TO w03;

START TRANSACTION;

-- レコード挿入前のテーブルを確認
SELECT * FROM users ORDER BY id;

-- CSVファイルからレコードを挿入
COPY users (id, name, age)
FROM
  '/tmp/insert-users.csv'
WITH
  (FORMAT csv, HEADER TRUE, NULL 'NULL', ENCODING 'UTF8');

-- レコード挿入後のテーブルを確認
SELECT * FROM users ORDER BY id;

ROLLBACK;
```

挿入後の結果セットは次のようになります。**David の age は空欄 (NULL)** となっていることを確認してください。

```
 id | name  | age
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
  3 | Carol |  18
  4 | David |
  5 | Ellen |  17
```

最後の `ROLLBACK` により、追加した3件は取り消されます。`SELECT * FROM w03.users ORDER BY id;` で、Alice と Bob の2件に戻ったことを確認してください。

`COPY` は **PostgreSQL 独自のコマンド** で、CSV ファイルなどの外部データを <span class="masked">高速</span> に取り込むことができます。`FROM` 句で指定するパス (ここでは `/tmp/insert-users.csv`) は、Docker コンテナ内のファイルパス ということに注意してください。

また、`WITH` 句 (**第13行目** から) では以下のような設定を行っています。

- `FORMAT csv` : ファイルが CSV 形式であることを明示
- `HEADER TRUE` : CSV の1行目をカラム名として無視
- `NULL 'NULL'` : CSV 内で「NULL」という文字列を NULL 値として扱う
- `ENCODING 'UTF8'` : 文字コードを UTF-8 として読み込む

その他、`WITH` 句のオプションについては、以下の[公式ドキュメント](https://www.postgresql.org/docs/current/sql-copy.html?utm_source=chatgpt.com)を参照してください。


::: prompts

- PostgreSQL において、`COPY ... WITH` 構文で CSVファイル からテーブルにデータを取り込みたいです。このとき、CSV ファイルには、改行やカンマを含む文字列データも含めたいです。どのように CSV ファイルを作成し、また、`WITH` 句にはどのようなオプションを指定すればよいですか。

- PostgreSQL では、`COPY ... WITH` 構文で CSVファイルからテーブルにデータを取り込みできます。MySQL でも同じ構文でデータの取り込みができますか。

:::
#### 定着確認

- PostgreSQL が Docker コンテナ内で動作している。SQLの `COPY users FROM '/tmp/insert-users.csv' WITH (FORMAT csv, HEADER TRUE);` に指定したパスは、ホストOSとコンテナのどちらのファイルを指すか答えよ。
  - **答え**: <span class="masked">コンテナ内のファイルを指す。</span>

- CSVの1行目が `id,name,age`、2行目以降がデータである。PostgreSQL の `COPY` で先頭行をデータとして取り込まないためのオプションを答えよ。
  - **答え**: <span class="masked">`HEADER TRUE`</span>

- **w03.users** の **age** はNULLを許すINTEGER型である。CSVの1行に `4,David,NULL` があり、`COPY users (id, name, age) ... WITH (FORMAT csv, HEADER TRUE, NULL 'NULL');` で取り込む。David の **age** は数値0、文字列NULL、SQLのNULLのどれになるか答えよ。
  - **答え**: <span class="masked">SQLのNULLになる。</span>

- **w03.users** には Alice と Bob の2件だけが登録されている。トランザクション内で、idが3・4・5の3件をCSVから取り込んだ。取込直後と、そのトランザクションを `ROLLBACK` した直後のレコード数を答えよ。
  - **答え**: <span class="masked">取込直後は5件、ROLLBACK直後は2件。</span>

## DELETE文 (基礎編)

テーブルからレコードを「削除」したいとき `DELETE` 文を使用します。実際に、次の SQL を実行してみてください。

```sql{.numberLines caption="テーブルからレコードを無条件で削除"}
SET
  search_path TO w03;

START TRANSACTION;

-- レコードを無条件削除
DELETE FROM characters;

-- 確認
SELECT * FROM characters;

ROLLBACK;
```

すべてのレコードが削除されたことが確認できます。

一方で、「**特定の条件を満たすレコードだけ**」を削除したいような場合は <span class="masked">`WHERE`句</span> を使用します。例えば、**last_login_at** が、2025年7月31日以前 (`NULL` を含む) のレコード**だけ**を削除したい場合、次のようにします。

```sql{.numberLines caption="WHERE句を指定して条件に一致するレコードだけを削除"}
SET
  search_path TO w03;

START TRANSACTION;

DELETE FROM characters
WHERE
  last_login_at IS NULL OR
  last_login_at <= '2025-07-31';

-- 確認
SELECT
  id,
  name,
  last_login_at
FROM
  characters
ORDER BY
  last_login_at;

ROLLBACK;
```

実行結果は、次のようになります。以下の **第02行目** の `DELETE 5` という応答から <span class="masked">5件のレコードが削除されたこと</span> が確認できます。

```
START TRANSACTION
DELETE 5
 id |  name  |    last_login_at
----+--------+---------------------
  8 | Bob    | 2025-08-03 09:11:00
 17 | Wendy  | 2025-08-08 10:56:00
 12 | Dave   | 2025-08-15 16:08:00
 13 | Mallet | 2025-08-27 18:50:00
 19 | Jack   | 2025-09-02 15:43:00
 10 | Oscar  | 2025-09-10 21:00:00
  9 | Walter | 2025-09-14 22:10:00
  6 | Alice  | 2025-09-18 14:22:00
 11 | Ellen  | 2025-09-25 23:55:00
  7 | Trudy  | 2025-09-29 12:37:00
 18 | Carol  | 2025-10-03 11:42:00
 16 | Steve  | 2025-10-06 09:14:00
 14 | Eve    | 2025-10-07 10:17:00
 15 | Trent  | 2025-10-11 17:20:00
(14 行)

ROLLBACK
```

#### 定着確認

- **w03.characters** の **id** はINTEGER型である。idが3または5のレコードだけを削除するDELETE文を、`IN` を使用して記述せよ。
  - **答え**: <span class="masked">`DELETE FROM w03.characters WHERE id IN (3, 5);`</span>

- **w03.characters** には19件のレコードがある。トランザクション内で `DELETE FROM w03.characters;` を実行した直後と、`ROLLBACK` した直後のレコード数を答えよ。
  - **答え**: <span class="masked">DELETE直後は0件、ROLLBACK直後は19件。</span>

- **w03.characters** の **last_login_at** はTIMESTAMP型で、未ログインの場合はNULLとなる。未ログインのレコードだけを削除するために指定するWHERE句を答えよ。
  - **答え**: <span class="masked">`WHERE last_login_at IS NULL`</span>

- PostgreSQL でDELETE文を実行したところ、`DELETE 5` と表示された。この応答が示す内容を答えよ。
  - **答え**: <span class="masked">5件のレコードが削除されたこと。</span>

#### SQLドリル💻

- `ex-01_1.sql` 👉 **w03.characters** テーブルのレコードについて、2025年10月15日を基準日として、最終ログインから60日以上経過したレコードを削除する SQL を記述せよ。日数は **last_login_at を DATE 型に変換し、基準日との差**で求めること。**last_login_at が NULL のレコードは削除しない**こと。
  - `DATE` 型の「2025年10月15日」は、`CAST('2025-10-15' AS DATE)` または `DATE '2025-10-15'` で得ることができます。

- `ex-01_2.sql` 👉 **w03.characters** テーブルのレコードについて、**last_login_at** が `NULL` で、**created_on** が2023年12月31日以前のレコードを削除する SQL を記述せよ。

- `ex-01_3.sql` 👉 **w03.characters** テーブルのレコードについて、**id** が「3」「5」「8」「9」「10」「14」の6件のレコードを削除する SQL を記述せよ。

## UPDATE文 (基礎編)

既存のレコードを更新したいときは `UPDATE` 文を使用します。`DELETE` 文と `INSERT` 文の組み合わせによっても、実質的に同様の処理は可能ですが、通常は `UPDATE` 文を使用します。

### すべてのレコードの値を固定値で更新

たとえば、**w03.characters** テーブルの全てのレコードについて、**バフ解除** (**buff** を `0.0` に上書き) するためには、次のように SQL を記述します。

```sql{.numberLines caption="すべてのレコードのbuffカラムを0.0に設定する"}
SET
  search_path TO w03;

START TRANSACTION;

-- 更新前のレコードを確認 (省略)

-- 更新処理
UPDATE characters
SET
  buff = 0.0;

-- 更新後のレコードを確認 (省略)

ROLLBACK;
```

実行すると `UPDATE 19` のような応答が表示されます。このとき、もともと `0.0` であったレコードについても、再度 `0.0` に上書きされ、処理件数に含まれている点に注意してください。

#### SQLドリル💻

- `ex-02_1.sql` 👉 **w03.characters** テーブルの全レコードの **buff** を `0.0` に更新する SQL を記述せよ。`START TRANSACTION` ～ `ROLLBACK` を含め、更新前後には **id**、**name**、**buff** を **id** の昇順で取得して、更新結果を確認すること。

### 特定のレコードのみを更新

特定のレコードを指定して値を更新する場合は、`WHERE` 句を使用します。なお、`UPDATE` 文の `SET` 句では、カンマで区切って <span class="masked">複数のカラムを同時に更新すること</span> ができます。

たとえば、**id** が「1」と「2」のキャラクタについて、**guild** カラムを `NULL` にして、**job** カラムを `Exile` (亡命者・追放者) に変更するには、次のように SQL を記述します。

```sql{.numberLines caption="特定のレコードを対象とした更新処理"}
SET
  search_path TO w03;

START TRANSACTION;

-- 更新前のレコードを確認 (省略)

-- 更新処理
UPDATE characters
SET
  guild = NULL,
  job = 'Exile'
WHERE
  id IN (1, 2);

-- 更新後のレコードを確認 (省略)

ROLLBACK;
```

実行すると `UPDATE 2` という応答が表示されます (2件のレコードが更新されたことが分かります)。トランザクション内の「更新後のレコードを確認」の箇所に `SELECT id, name, job, guild FROM characters ORDER BY id;` を記述すると、次のように表示されます (先頭2件を抜粋)。

```
 id |  name   |   job   | guild
----+---------+---------+--------
  1 | Marvin  | Exile   |
  2 | Zach    | Exile   |
 ～～以下略～～
```

#### SQLドリル💻

- `ex-02_2.sql` 👉 **w03.characters** テーブルの **job** カラムについて `Wizard` を `Mage` に更新する SQL を記述せよ。


### 現在の値を利用した更新

`UPDATE` 文では <span class="masked">現在のカラム値</span> を参照した更新も可能です。たとえば、**level** を `現在値+2` にするには、次のように SQL を記述します。

- 実際に実行するときは `START TRANSACTION` ～ `ROLLBACK` の内部で実行してください。

```sql{.numberLines caption="levelを2だけ増加させる更新"}
SET
  search_path TO w03;

START TRANSACTION;

UPDATE characters
SET
  level = level + 2;

ROLLBACK;
```

また、同じレコードのなかの「**他のカラム値**」を参照して更新することもできます。たとえば、**buff** を `SQRT(100-level)*0.05` に設定するには、次のように SQL を記述します。

- `SQRT` は平方根を計算する関数です。

```sql{.numberLines caption="同じレコード内の他のカラム値を参照して更新"}
SET
  search_path TO w03;

START TRANSACTION;

UPDATE characters
SET
  buff = SQRT(100 - level)*0.05;

ROLLBACK;
```

#### SQLドリル💻

- `ex-02_3.sql` 👉 ソロプレイ前衛職応援キャンペーン🎉として、**w03.characters** テーブルの **guild** が `NULL` で、**job** が Fighter、Monk、Samurai、Ninja のキャラクタについて、**buff** の現在値に `0.25` を加算する SQL を記述せよ。また、更新前後の **buff** などを確認する SQL も記述すること。

- `ex-02_4.sql` 👉 おかえりなさいキャンペーン🎉として、**w03.characters** テーブルの **buff** を、2025年10月15日を基準日とした最終ログインからの経過日数に応じて、次の値に **上書き** する SQL を記述せよ。日数は **last_login_at を DATE 型に変換し、基準日との差**で求めること。複数の条件に該当するときは、日数の大きい条件を優先し、**last_login_at が NULL の場合は buff を `0.00`** にすること。更新前後の **buff** も確認すること。
  - 最終ログイン日から **60日以上** 経過していれば **buff** を `0.40`
  - 最終ログイン日から **40日以上** 経過していれば **buff** を `0.30`
  - 最終ログイン日から **20日以上** 経過していれば **buff** を `0.20`
  - 最終ログイン日から **10日以上** 経過していれば **buff** を `0.10`
  - それ以外は  **buff** を `0.00` に設定

### CASE式による同時置換処理

**w03.characters** テーブルの **job** カラムについて、(ハロウィン仮装イベント🎃として) Priest なら Wizard に更新し、Wizard なら Priest に更新するような処理 (つまり、<span class="masked">Priest ↔ Wizard の入れ替え処理</span>) を考えます。

この処理を次のように**2回に分けて実行すると**、期待する結果をえることができません。

```sql{.numberLines caption="2回に分けて更新処理を実行"}
SET
  search_path TO w03;

START TRANSACTION;

-- 更新前のレコードを確認
SELECT
  id,
  name,
  job
FROM
  characters
WHERE
  job IN ('Wizard', 'Priest')
ORDER BY
  id;

-- 更新処理 👉 Priest ならば Wizard に変更
UPDATE characters
SET
  job = 'Wizard'
WHERE
  job = 'Priest';

-- 更新処理 👉 Wizard ならば Priest に変更
UPDATE characters
SET
  job = 'Priest'
WHERE
  job = 'Wizard';

-- 更新後のレコードを確認
SELECT
  id,
  name,
  job
FROM
  characters
WHERE
  job IN ('Wizard', 'Priest')
ORDER BY
  id;

ROLLBACK;
```

実行結果は、次のようになります。期待したジョブの入れ替えとはならず、<span class="masked">全員が Priest</span> になってしまっています。

```
START TRANSACTION
 id |  name   |  job
----+---------+--------
  1 | Marvin  | Priest
  3 | Charlie | Wizard
  6 | Alice   | Priest
 11 | Ellen   | Wizard
 13 | Mallet  | Wizard
 15 | Trent   | Priest
 18 | Carol   | Priest
 19 | Jack    | Wizard
(8 行)

UPDATE 4
UPDATE 8
 id |  name   |  job
----+---------+--------
  1 | Marvin  | Priest
  3 | Charlie | Priest
  6 | Alice   | Priest
 11 | Ellen   | Priest
 13 | Mallet  | Priest
 15 | Trent   | Priest
 18 | Carol   | Priest
 19 | Jack    | Priest
(8 行)

ROLLBACK
```

このような場合、いったん別の値に退避してから入れ替える方法でも対応できますが、次のように **CASE式** を使用することで、より簡潔に SQL を記述することができます。

```sql{.numberLines caption="CASE式による同時置換処理"}
SET
  search_path TO w03;

START TRANSACTION;

-- 更新前のレコードを確認 (省略)

-- 更新処理 👉 Priest と Wizard を入れ替え
UPDATE characters
SET
  job = CASE
    WHEN job = 'Priest' THEN 'Wizard'
    ELSE 'Priest'
  END
WHERE
  job IN ('Wizard', 'Priest');

-- 更新後のレコードを確認 (省略)

ROLLBACK;
```

トランザクション内の「更新後のレコードを確認」の箇所に、先ほどの例と同じ `SELECT` 文を記述すると、以下のように意図したジョブの入れ替えを確認できます。

```
 id |  name   |  job
----+---------+--------
  1 | Marvin  | Wizard
  3 | Charlie | Priest
  6 | Alice   | Wizard
 11 | Ellen   | Priest
 13 | Mallet  | Priest
 15 | Trent   | Wizard
 18 | Carol   | Wizard
 19 | Jack    | Priest
```

#### SQLドリル💻

- `ex-02_5.sql` 👉 **w03.characters** テーブルについて、前衛職のジョブを次のように入れ替えるための SQL を記述せよ。
  - Fighter を Monk に変更
  - Monk を Samurai に変更
  - Samurai を Ninja に変更
  - Ninja を Fighter に変更
  - それ以外のジョブは変更しないこと。更新前後の **job** を確認すること。

### 補足: RETURNING句

PostgreSQL では、`UPDATE` 文や `DELETE` 文を実行した際、変更後 (または削除した) レコードの内容を即座に取得できる `RETURNING` 句という構文があります。通常の `UPDATE` 文は、`UPDATE 2` のように**件数だけ**を返しますが、`RETURNING` を使うと <span class="masked">変更後のレコードを受け取り、任意のカラムを出力すること</span> ができます。

```sql{.numberLines caption="RETURNING句の利用"}
SET
  search_path TO w03;

START TRANSACTION;

UPDATE characters
SET
  buff = 0.3
WHERE
  level < 40
RETURNING -- ◀ ここに注目
  id,
  name,
  level,
  buff;

ROLLBACK;
```

実行結果は次のようになります。

```
START TRANSACTION
 id |  name  | level | buff
----+--------+-------+------
  1 | Marvin |    35 | 0.30
  4 | Tom    |     1 | 0.30
  5 | Ivan   |    39 | 0.30
  8 | Bob    |    33 | 0.30
 18 | Carol  |    28 | 0.30
(5 行)

UPDATE 5
ROLLBACK
```

#### 定着確認

- **characters** テーブルのあるレコードの **buff** はNUMERIC型で、値は `-0.15` である。`SET buff = 0.25` と `SET buff = buff + 0.25` をそれぞれ元の値に対して適用した場合、更新後の値を答えよ。
  - **答え**: <span class="masked">前者は0.25、後者は0.10。</span>

- **w03.characters** には19件のレコードがあり、うち3件の **buff** は既に0.0である。`UPDATE w03.characters SET buff = 0.0;` を実行したとき、`UPDATE` の応答に表示される件数は16と19のどちらか答えよ。
  - **答え**: <span class="masked">19。WHERE句がなく全レコードが対象となり、既に同じ値の行も更新件数に含まれる。</span>

- **w03.characters** の **job** はVARCHAR型である。WizardのレコードだけをMageに変更するUPDATE文を記述せよ。
  - **答え**: <span class="masked">`UPDATE w03.characters SET job = 'Mage' WHERE job = 'Wizard';`</span>

- **characters** テーブルには、**job** がPriestのAliceと、WizardのBobだけが登録されている。`UPDATE characters SET job = 'Wizard' WHERE job = 'Priest';` の後に、`UPDATE characters SET job = 'Priest' WHERE job = 'Wizard';` を実行した。最後の2人のjobを答えよ。
  - **答え**: <span class="masked">AliceもBobもPriestとなる。最初のUPDATEでWizardになったAliceも、2つ目のUPDATEの対象になるため。</span>

- PostgreSQL でUPDATE文を実行し、更新した行の **id** と、更新後の **buff** を同じSQL文で取得したい。文末に追加する句を答えよ。
  - **答え**: <span class="masked">`RETURNING id, buff`</span>

## 集約関数 (Aggregate Function)

SQL には、`COUNT`、`SUM`、`MIN`、`MAX`、`AVG` などの **集約処理**（**集計処理**）を実行する関数が用意されています。これらは一般に **集約関数** (**Aggregate Function**、集計関数とも呼ばれる) と呼ばれ、基本的には `SELECT` 句および、後で解説する `HAVING` 句のなかだけで使用することができます。

### COUNT関数

`COUNT` 関数は、引数として指定したカラムのうち、`NULL` **ではないレコード数**を求める関数となります。ただし、引数にアスタリスク `*` を指定した場合は、テーブル全体のレコード件数を取得します (このとき、すべてのカラムが `NULL` のレコードがあっても、それを「1」とカウントします)。

次の SQL の実行結果を予想し、その後、実際に実行して結果を確認してください。

```sql{.numberLines caption="COUNT関数の利用例"}
SET
  search_path TO w03;

SELECT
  COUNT(*) AS "num_record",
  COUNT(name) AS "num_name", 
  COUNT(guild) AS "num_guild",
  COUNT(last_login_at) AS "num_last_login_at"
FROM
  characters;
```

実際の実行結果は次のようになります。

```
 num_record | num_name | num_guild | num_last_login_at
------------+----------+-----------+-------------------
         19 |       19 |        14 |                18
```

**w03.characters** には 19件 のレコードが存在するので、`COUNT(*)` は「19」となります。また、**name** カラムは `NULL` が許可されないので (＝`NULL` のフィールドを含まないので)、`COUNT(name)` は `COUNT(*) ` と同じく「19」となります。

一方で、**guild** カラムは `NULL` を許可しており、5名がギルド無所属のため `COUNT(guild)` は「14」となります。また、**last_login_at** には、1件の `NULL` を含むので `COUNT(last_login_at)` は「18」となります。

#### 重複を無視する

`COUNT` 関数では、引数に指定するカラム名の前に `DISTINCT` キーワードをつけることができます。`DISTINCT` は、[第03回講義](lecture03.html#レコードの重複を省く)で学んだように <span class="masked">重複を省く</span> ためのキーワードであり、`COUNT` 関数のなかで使用することで、**重複を除いた値の件数** を数えることができます。

次の SQL の実行結果を予想し、その後、実際に実行して結果を確認してください。

```sql{.numberLines caption="COUNT関数の利用例(DISTINCT付き)"}
SET
  search_path TO w03;

SELECT
  COUNT(*) AS "num_record",
  COUNT(DISTINCT job) AS "num_job_distinct",
  COUNT(DISTINCT guild) AS "num_guild_distinct"
FROM
  characters;
```

実際の実行結果は次のようになります。

```
 num_record | num_job_distinct | num_guild_distinct
------------+------------------+--------------------
         19 |                6 |                  3
```

いま **job** カラムには「Fighter」「Monk」「Samurai」「Ninja」「Wizard」「Priest」の6種類が存在するため `COUNT(DISTINCT job)` は「**6**」となります。

また、**guild** カラムには「Yamato」「D.D.D」「hameln」「NULL」の4種類が存在しますが <span class="masked">`NULL` はカウントされない</span> ため `COUNT(DISTINCT guild)` は「**3**」となります。

- <i class="fa-brands fa-github"></i>[from-teacher/03/init-characters.sql](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/from-teacher/03/init-characters.sql) 参考

#### 定着確認

- あるテーブルの **guild** カラムには、`A`、`A`、`B`、`NULL`、`NULL` の5件が格納されている。WHERE句を指定せずに `COUNT(*)`、`COUNT(guild)`、`COUNT(DISTINCT guild)` を求めた結果を、それぞれ答えよ。
  - **答え**: <span class="masked">順に5、3、2。</span>

- **w03.characters** の **guild** がNULLであるレコードは5件存在する。`SELECT COUNT(*) FROM w03.characters WHERE guild IS NULL;` の結果は19と5のどちらか答えよ。
  - **答え**: <span class="masked">5。WHERE句によって絞り込まれたレコードを数える。</span>

- あるテーブルの **age** カラムには、`18`、`20`、`NULL` の3件がある。`SELECT COUNT(age) FROM テーブル名;` は、値の合計38、平均19、NULL以外の件数2のどれを返すか答えよ。
  - **答え**: <span class="masked">NULL以外の件数2を返す。</span>

- あるテーブルの **guild** カラムには、`A`、`A`、`B`、`NULL` の4件がある。ギルド名の種類を、NULLを除いて数える集約式を記述せよ。
  - **答え**: <span class="masked">`COUNT(DISTINCT guild)`</span>

#### SQLドリル💻

- `ex-03_1.sql` 👉 **w03.characters** テーブルから次のような結果セットを得る SQL を記述せよ。

```
 ジョブ種 
----------
 6種類
```

- `ex-03_2.sql` 👉 **w03.characters** テーブルから次のような結果セットを得る SQL を記述せよ。

```
 ギルド所属 | 無所属 
------------+--------
 14人       | 5人
```

### SUM関数とAVG関数

`SUM` 関数は引数として指定したカラムの「**合計**」を求める関数、`AVG` 関数は引数として指定したカラムの「**平均**」を求める関数となります。いずれも、<span class="masked">数値型のカラムだけ</span> を引数にとることができます。

- いずれの関数も `COUNT` 関数のように、アスタリスク `*` を引数にとることはできません。
- いずれの関数も `NULL` は除外されます。例えば、**num** というカラムがあったとして、その値が `3`、`5`、`NULL` のとき `AVG(num)` は $(3+5)/2$ で `4` となります。  


次の SQL の実行結果を予想し、その後、実際に実行して結果を確認してください。

```sql{.numberLines caption="SUM関数とAVG関数の利用例"}
SET
  search_path TO w03;

SELECT
  ROUND(AVG(level),1) AS "avg_level",
  SUM(level) AS "sum_level"
FROM
  characters;
```

実際の実行結果は次のようになります。なお、上記の**第05行目**の `ROUND` は[第03回講義](lecture03.html#カラム値に文字列演算と算術演算を適用する)で紹介したように四捨五入を適用する関数になります。

```
 avg_level | sum_level
-----------+-----------
      48.8 |       928
```

#### NULL値を特定値に置き換えて合計や平均を求めたい場合

`NULL` を特定の数値に置き換えて `SUM` 関数や `AVG` 関数を適用したい場合、`COALESCE` 関数を組み合わせます。

次の SQL は、**age** カラムが `NULL` のとき、それを `16` に置き換えて合計と平均を適用するものです。実行結果を予想し、その後、実際に実行して結果を確認してください。

この例も **w03.users** が Alice と Bob の2件であることを前提とします。別のレコードを残している場合は、**既存データが初期状態に戻ることを確認したうえで**、次のコマンドで初期化してください。

```bash
npm run sql from-teacher/03/init-users.sql
```

```sql{.numberLines caption="SUM関数とAVG関数の利用例"}
SET
  search_path TO w03;

START TRANSACTION;

INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18),
  (4, 'Dave', NULL),
  (5, 'Ellen', 17);

SELECT * FROM users ORDER BY id;

SELECT
  SUM(age) AS "sum",
  SUM(COALESCE(age, 16)) AS "sum_with_default",
  ROUND(AVG(age), 1) AS "avg",
  ROUND(AVG(COALESCE(age, 16)), 1) AS "avg_with_default"
FROM
  users;

ROLLBACK;
```

実際の実行結果は次のようになります。

```
START TRANSACTION
INSERT 0 3
 id | name  | age
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
  3 | Carol |  18
  4 | Dave  |
  5 | Ellen |  17
(5 行)

 sum | sum_with_default | avg  | avg_with_default
-----+------------------+------+------------------
  80 |               96 | 20.0 |             19.2
(1 行)

ROLLBACK
```

#### 定着確認

- あるテーブルの **num** はINTEGER型で、`3`、`5`、`NULL` の3件がある。`SUM(num)` と `AVG(num)` の結果を答えよ。
  - **答え**: <span class="masked">SUMは8、AVGは4。NULLは計算の対象から除外される。</span>

- あるテーブルの **age** はINTEGER型で、`18`、`20`、`NULL` の3件がある。NULLを16に置き換えて平均する `AVG(COALESCE(age, 16))` の結果を答えよ。
  - **答え**: <span class="masked">18。NULLを含む3件を対象に、(18+20+16)/3を計算する。</span>

- **w03.characters** の **level** はINTEGER型、**guild** はVARCHAR型で、無所属の場合はNULLとなる。無所属のレコードだけを対象に、平均レベルの小数第3位を四捨五入して、小数第2位まで表示するSELECT文を記述せよ。
  - **答え**: <span class="masked">`SELECT ROUND(AVG(level), 2) FROM w03.characters WHERE guild IS NULL;`</span>

#### SQLドリル💻

- `ex-03_3.sql` 👉 **w03.characters** テーブルから、次のようにギルド無所属 (＝**guild** が `NULL`) のキャラクタについて、レベルの平均と合計を求める SQL を記述せよ。ただし、レベルの平均は小数第3位を四捨五入して、小数第2位まで表示すること。
  - **ヒント** : <span class="masked">ギルド無所属のキャラクタだけを対象にするには `WHERE` 句を利用する</span>

```
 無所属平均Lv | 無所属合計Lv 
--------------+--------------
        39.60 |          198
```

- `ex-03_4.sql` 👉 **w03.characters** テーブルから、前衛職 (Fighter、Monk、Samurai、Ninja) の人数と平均レベル、後衛職 (Wizard、Priest) の人数と平均レベルを求める SQL を記述せよ (ここでは、`WHERE` 句で対象の職を絞り込む2つの `SELECT` 文を記述すること)。ただし、レベルの平均は小数第2位を四捨五入して、小数第1位まで表示すること。

```
 前衛職人数 | 前衛職平均Lv 
------------+--------------
         11 |         49.1

 後衛職人数 | 後衛職平均Lv
------------+--------------
          8 |         48.5
```

### MAX関数とMIN関数

`MAX` 関数と `MIN` 関数は、引数として指定したカラムの「**最大値**」と「**最小値**」を求める関数となります。いずれの関数も、数値型の他、**日時型** (`DATE`や`TIMESTAMP`)、**文字列型**などのカラムに適用することができます。

- いずれの関数も `COUNT` 関数のように、アスタリスク `*` を引数にとることはできません。
- いずれの関数も `NULL` は除外されます。
- 日時型に適用した場合、`MAX` は最も未来の値 (降順に整列した先頭) 、`MIN` は最も過去の値 (昇順に整列した先頭) を返します。
- 文字列に適用した場合、`MAX` は辞書順の最後 (＝昇順に並べたときの末尾) の値を、`MIN` は辞書順の最初 (＝昇順に並べたときの先頭) の値を返します。

次の SQL の実行結果を予想し、その後、実際に実行して結果を確認してください。

```sql{.numberLines caption="MAX関数とMIN関数の利用例"}
SET
  search_path TO w03;

SELECT
  MIN(level) AS "min_lv",
  MAX(level) AS "max_lv",
  MIN(name) AS "min_name",
  MAX(name) AS "max_name"
FROM
  characters;

SELECT
  MIN(created_on) AS "min_created_on",
  MAX(created_on) AS "max_created_on"
FROM
  characters;
```

実際の実行結果は次のようになります。

```
 min_lv | max_lv | min_name | max_name
--------+--------+----------+----------
      1 |     73 | Alice    | Zach
(1 行)

 min_created_on | max_created_on
----------------+----------------
 2020-09-23     | 2024-07-12
(1 行)
```

#### 文字数のカウント

文字列型に対して、**文字数をカウントしたい場合** は `LENGTH` 関数を使用します。次の SQL の実行結果を予想し、その後、実際に実行して結果を確認してください。

```sql{.numberLines caption="最小文字数と最大文字数を求める例"}
SET
  search_path TO w03;

SELECT
  MIN(LENGTH(name)) AS "min_len_name",
  MAX(LENGTH(name)) AS "max_len_name"
FROM
  characters;
```

実際の実行結果は次のようになります。

```
 min_len_name | max_len_name
--------------+--------------
            3 |            7
```

::: {.note .type-senior}
**EX: 最も短い名前と最も長い名前を取得する**

今後の講義で学ぶ「**サブクエリ**」というものを利用すると、テーブルのなかから「最も短い名前」や「最も長い名前」を抽出することができます。

```sql{.numberLines caption="「最も短い名前」と「最も長い名前」を取得する"}
SET
  search_path TO w03;

SELECT
  name AS "最も短い名前"
FROM
  characters
WHERE
  LENGTH(name) = (
    SELECT
      MIN(LENGTH(name))
    FROM
      characters
  );

SELECT
  name AS "最も長い名前"
FROM
  characters
WHERE
  LENGTH(name) = (
    SELECT
      MAX(LENGTH(name))
    FROM
      characters
  );
```

実行結果は次のようになります。

```
 最も短い名前
--------------
 Tom
 Bob
 Eve
(3 行)

 最も長い名前
--------------
 Charlie
(1 行)
```

:::

#### 定着確認

- あるテーブルの **name** はVARCHAR型で、Tom、Charlie、Bobの3件がある。`MIN(LENGTH(name))` と `MAX(LENGTH(name))` の結果を答えよ。
  - **答え**: <span class="masked">順に3と7。文字列自体ではなく、文字数の最小値と最大値を返す。</span>

- あるテーブルの **last_login_at** はTIMESTAMP型で、`2025-07-01 10:00:00`、`2025-08-01 09:00:00`、`NULL` の3件がある。`MIN(last_login_at)` と `MAX(last_login_at)` の結果を答えよ。
  - **答え**: <span class="masked">MINは2025-07-01 10:00:00、MAXは2025-08-01 09:00:00。NULLは除外される。</span>

- **w03.characters** の **buff** はNUMERIC型である。最大値と最小値の差を求める集約式を記述せよ。
  - **答え**: <span class="masked">`MAX(buff) - MIN(buff)`</span>

#### SQLドリル💻

- `ex-03_5.sql` 👉 **w03.characters** テーブルから、次に示すように **buff** カラムの「最小値」「最大値」「最大値と最小値の差」を求める SQL を記述せよ。

```
 min_buff | max_buff | max-min 
----------+----------+---------
    -0.20 |     0.10 |    0.30
```
- `ex-03_6.sql` 👉 **w03.characters** テーブルにおいて、最も長いギルド名が何文字かを求める SQL を記述せよ。ただし、**guild** カラムの `NULL` 値は `Freelancer` という文字列に置き換えて評価すること。

## GROUP BY

`SELECT` 文に `GROUP BY` 句を使うと **指定したカラムでグループ化処理を行い**、各グループに対して集約関数を適用することができます。

例えば、**job** ごとに「人数」「最大レベル」「平均レベル」を求める SQL は次のようになります。なお、`GROUP BY` 句に指定するカラムのことを <span class="masked">集約キー</span> と言います。

```sql{.numberLines caption="GROUP BY句の利用"}
SET
  search_path TO w03;

SELECT
  job,
  COUNT(*) AS "num",
  MAX(level) AS "max_lv",
  ROUND(AVG(level),1) AS "avg_lv"
FROM
  characters
GROUP BY
  job -- ◀ job でグループ化処理
ORDER BY
  job;
```

実行結果は、次のようになります。

```
   job   | num | max_lv | avg_lv
---------+-----+--------+--------
 Fighter |   4 |     56 |   37.3
 Monk    |   2 |     39 |   36.0
 Ninja   |   2 |     62 |   54.0
 Priest  |   4 |     50 |   38.8
 Samurai |   3 |     73 |   70.3
 Wizard  |   4 |     64 |   58.3
```

なお、`SELECT` 文は、`SELECT` 句 👉 `FROM` 句 👉 `WHERE` 句 👉 `GROUP BY` 句 👉 `ORDER BY` 句 👉 (`LIMIT` 句 / `OFFSET` 句) という順で記述しないと**構文エラー**になるので注意してください。

#### 集約キーにNULLが含まれる場合の挙動

集約キー (`GROUP BY` で指定するカラム) に `NULL` が含まれる場合、`NULL` も「ひとつのグループ」として扱われます。これも、実際に実行結果をみたほうが分かりやすいと思います。

値に `NULL` を含む **guild** カラムを「集約キー」に使用します。

```sql{.numberLines caption="GROUP BY句の集約キーにNULLが含まれる場合"}
SET
  search_path TO w03;

SELECT
  guild,
  COUNT(*) AS "num",
  MAX(level) AS "max_lv",
  ROUND(AVG(level),1) AS "avg_lv"
FROM
  characters
GROUP BY
  guild -- ◀ guild を集約キーに指定
ORDER BY
  LOWER(guild); -- ◀ 大文字と小文字を区別せずに整列
```

実行結果は、次のようになります。

```
 guild  | num | max_lv | avg_lv
--------+-----+--------+--------
 D.D.D  |   5 |     64 |   55.8
 hameln |   4 |     70 |   52.0
 Yamato |   5 |     68 |   48.6
        |   5 |     73 |   39.6
```

最終行に **guild** が `NULL` のキャラクタ (ギルド無所属のキャラクタ) に対する集計が出力されています。`NULL` は空欄で表示されるので、任意の文字列に置き換えたいときは `COALESCE` を使用します。

例えば、`SELECT` 句の `guild` を `COALESCE(guild,'Freelancer') AS "guild"` に書き換えると以下のような結果を得ることができます。

```
   guild    | num | max_lv | avg_lv 
------------+-----+--------+--------
 D.D.D      |   5 |     64 |   55.8
 hameln     |   4 |     70 |   52.0
 Yamato     |   5 |     68 |   48.6
 Freelancer |   5 |     73 |   39.6
```
#### SQLドリル💻

- `ex-04_1.sql` 👉 **w03.characters** テーブルから、次のような結果セットを得る SQL を記述せよ。
    - **guild** が `NULL` のグループを先頭に配置し、その **guild** を「無所属」という文字列に置き換えて表示すること。
    - **guild** が `Yamato` のグループを結果セットに含めないこと。

```
 guild  | num | max_lv | min_lv | max_buff | min_buff
--------+-----+--------+--------+----------+----------
 無所属 |   5 |     73 |      1 |     0.00 |    -0.20
 D.D.D  |   5 |     64 |     46 |     0.10 |     0.10
 hameln |   4 |     70 |     33 |     0.05 |     0.05
```

- `ex-04_2.sql` 👉 **w03.characters** テーブルから、次のような結果セットを得る SQL を記述せよ。
  - 平均レベルは小数第2位を四捨五入して、小数第1位まで表示すること。
  - 平均レベルの降順に整列 (ソート) すること。

```
   job   | num | avg_lv 
---------+-----+--------
 Samurai |   3 |   70.3
 Wizard  |   4 |   58.3
 Ninja   |   2 |   54.0
 Priest  |   4 |   38.8
 Fighter |   4 |   37.3
 Monk    |   2 |   36.0
```

### GROUP BY句の使用時にSELECT句で指定可能な値 (重要🚨)

`GROUP BY` 句を使用したとき、`SELECT` 句に記述可能なカラムは「`GROUP BY` **で指定したカラム (＝集約キー) に限られる**」というルールがあります。たとえば、`GROUP BY job` としたとき、`SELECT` 句にそのまま記述できるカラムは <span class="masked">`job`</span> だけであり、<span class="masked">`id` や `level`、`name`、`guild`</span> などを直接指定することはできません。それらを利用したい場合は、`MAX(id)` や `AVG(level)` のように集約関数 (グループごとに計算する関数) を適用する必要があります。

実際に、次の SQL が「**エラーになること**」を確認してください。

```sql{.numberLines caption="集約キー以外のカラムをSELECT句に指定"}
SET
  search_path TO w03;

SELECT
  job,
  level -- 集約キー以外のカラムを指定
FROM
  characters
GROUP BY
  job; -- 集約キーは job
```

実行結果は、次のようになります。

```
psql:<stdin>:10: ERROR:  列"characters.level"はGROUP BY句で指定するか、集約関数内で使用しなければなりません
```

英語環境では次のようになります。

```
psql:<stdin>:10: ERROR:  column "characters.level" must appear in the GROUP BY clause or be used in an aggregate function
```

**第06行目** の `level` を、集約関数を適用した形 (たとえば `MAX(level)` や `AVG(level)`) にすると問題なく実行できることを確認してください。

::: prompts
- SQLにおいて、`GROUP BY` 句に指定したカラム以外を、`SELECT` 句に指定するとエラーになるのはなぜですか。たとえば、`SELECT job, level FROM w03.characters GROUP BY job;` がエラーになるのはなぜですか。
:::

### GROUP BY句に複数の集約キーを指定

GROUP BY句には、以下のように **複数のカラム** を指定することができます。

```sql{.numberLines caption="GROUP BY句に複数の集約キーを指定"}
SET
  search_path TO w03;

SELECT
  COALESCE(guild, '(Freelancer)') AS "guild",
  job,
  COUNT(*)
FROM
  characters
GROUP BY
  guild,
  job
ORDER BY
  guild,
  job;
```

実行結果は次のようになります。実行結果からわかるように、まず **guild** ごとにグループ化され、その内部でさらに **job** ごとにグループ化されています。つまり、2つのカラムを組み合わせて「ギルド×ジョブ」単位で件数を集計できていることが確認できます。

```
    guild     |   job   | count
--------------+---------+-------
 (Freelancer) | Fighter |     1
 (Freelancer) | Monk    |     1
 (Freelancer) | Priest  |     1
 (Freelancer) | Samurai |     1
 (Freelancer) | Wizard  |     1
 D.D.D        | Fighter |     1
 D.D.D        | Ninja   |     2
 D.D.D        | Wizard  |     2
 Yamato       | Fighter |     1
 Yamato       | Priest  |     3
 Yamato       | Samurai |     1
 hameln       | Fighter |     1
 hameln       | Monk    |     1
 hameln       | Samurai |     1
 hameln       | Wizard  |     1
```

- `GROUP BY` の集約キーの順序を変えても (すなわち `GROUP BY guild, job` を `GROUP BY job, guild` に変更しても)、結果セットが同じになることを確認してください。
  - ただし `ORDER BY` 句を指定しない場合、整列順が変わる可能性があります。

::: prompts
- SQLにおいて、`GROUP BY guild, job` を `GROUP BY job, guild` に書き換えても (`ORDER BY` 句が指定されている限りは)、結果セットが変わらないのはなぜですか。集約キーの順番は関係ないのですか。
:::

#### SQLドリル

- `ex-04_3.sql` 👉 **w03.characters** テーブルから、次のような結果セットを得るような SQL を記述せよ。
  - 平均レベルは小数第2位を四捨五入して、小数第1位まで表示すること。
  - 後衛職 (Priest、Wizard) のみを対象とすること。

```
  job   | guild  | count | avg_lv 
--------+--------+-------+--------
 Priest | Yamato |     3 |   42.3
 Priest |        |     1 |   28.0
 Wizard | D.D.D  |     2 |   57.5
 Wizard | hameln |     1 |   61.0
 Wizard |        |     1 |   57.0
```

### ROLLUPによる全体集計

`GROUP BY` でカテゴリ別に集計したときに、「**レコード全体の集計**」も同時に出力したいときは、`ROLLUP` という `GROUP BY` 句の拡張構文を使用します。たとえば、以下のようにすると「`guild` ごとの集計」に「全体の集計」を加えた結果セットを取得することができます。

```sql{.numberLines caption="ROLLUPの利用"}
SET
  search_path TO w03;

SELECT
  guild,
  ROUND(AVG(level), 1) AS "avg_lv",
  COUNT(*) AS "num"
FROM
  characters
GROUP BY
  ROLLUP (guild) -- ◀ ここに注目
ORDER BY
  guild,
  GROUPING(guild) DESC; -- NULLの2行は全体集計、無所属の順
```

実行結果は、次のようになります。**guild** が空欄の2行のうち、**num が `5` の行** がギルド無所属のキャラクタの集計、**num が `19` の行** がテーブル全体の集計となります。ここでは、後述する `GROUPING` 関数により、全体集計の行を先に表示しています。

```
 guild  | avg_lv | num
--------+--------+-----
 D.D.D  |   55.8 |   5
 Yamato |   48.6 |   5
 hameln |   52.0 |   4
        |   48.8 |  19
        |   39.6 |   5
```

空欄を別の文字に置き換えたいときは、次のように `GROUPING` 関数と **CASE式** を組み合わせて利用します。ここで `GROUPING(guild)` は、集計行なら`1`、通常行なら `0` を返す特殊関数です。

```sql{.numberLines caption="GROUPING関数の利用"}
SET
  search_path TO w03;

SELECT
  CASE
    WHEN GROUPING(guild) = 1 THEN '(Total)'
    WHEN guild IS NULL THEN '(Freelancer)'
    ELSE guild
  END AS "guild",
  ROUND(AVG(level), 1) AS "avg_lv",
  COUNT(*) AS "num"
FROM
  characters
GROUP BY
  ROLLUP (guild)
ORDER BY
  guild;
```

実行結果は次のようになります。

```
    guild     | avg_lv | num
--------------+--------+-----
 (Freelancer) |   39.6 |   5
 (Total)      |   48.8 |  19
 D.D.D        |   55.8 |   5
 Yamato       |   48.6 |   5
 hameln       |   52.0 |   4
```

::: {.note .type-senior}
**EX: 並び順も厳密に制御したいときは...**

次のように `ORDER BY` 句のなかで、`GROUPING` 関数と **CASE式** を組み合わせて利用します。

```sql{.numberLines caption="GROUPING関数の利用"}
SET
  search_path TO w03;

SELECT
  CASE
    WHEN GROUPING(guild) = 1 THEN '(Total)'
    WHEN guild IS NULL THEN '(Freelancer)'
    ELSE guild
  END AS "guild",
  ROUND(AVG(level), 1) AS "avg_lv",
  COUNT(*) AS "num"
FROM
  characters
GROUP BY
  ROLLUP (guild)
ORDER BY
  CASE -- ◀ ここからに注目
    WHEN GROUPING(guild) = 1 THEN 3 -- 整列順第3位
    WHEN guild IS NULL THEN 2 -- 整列順第2位
    ELSE 1 -- 整列順第1位
  END,
  LOWER(guild); -- 整列順第1位のなかで大文字と小文字を区別せず昇順
```

実行結果は次のようになります。

```
    guild     | avg_lv | num
--------------+--------+-----
 D.D.D        |   55.8 |   5
 hameln       |   52.0 |   4
 Yamato       |   48.6 |   5
 (Freelancer) |   39.6 |   5
 (Total)      |   48.8 |  19
```

なお、`ROLLUP` の結果を含めた並び順や表示体裁の細かい制御は、SQLでも実現は可能ですが、**複雑になりやすい処理**です。可読性や保守性を考えると、最終的な表示順や体裁はアプリケーション側で調整するほうが実用的なケースも多いことを覚えておいてください。
:::

#### SQLドリル💻

- `ex-04_4.sql` 👉 **w03.characters** テーブルから、次のように **job** ごとに最大レベル、平均レベル、人数を得るような SQL を記述せよ。
  - 平均レベルは小数第2位を四捨五入して、小数第1位まで表示すること。
  - 全体についても、同様の集計処理を実施して `-TOTAL-` というラベルをつけること。

```
   job   | max_lv | avg_lv | num 
---------+--------+--------+-----
 -TOTAL- |     73 |   48.8 |  19
 Fighter |     56 |   37.3 |   4
 Monk    |     39 |   36.0 |   2
 Ninja   |     62 |   54.0 |   2
 Priest  |     50 |   38.8 |   4
 Samurai |     73 |   70.3 |   3
 Wizard  |     64 |   58.3 |   4
```

### GROUP BY句にCASE式を利用

`GROUP BY` 句に **CASE式** を利用することで、**より柔軟にグループを定義して**集計処理をすることが可能となります。たとえば「ギルド所属者」と「無所属者」でグループを分けて集計処理をしたい場合は、次のように SQL を記述します。

```sql{.numberLines caption="GROUP BY句 に CASE式 を利用"}
SET
  search_path TO w03;

SELECT
  CASE
    WHEN guild IS NULL THEN '無所属'
    ELSE 'ギルド所属'
  END AS "カテゴリ",
  ROUND(AVG(level), 1) AS "avg_lv",
  COUNT(*) AS "num"
FROM
  characters
GROUP BY
  CASE
    WHEN guild IS NULL THEN '無所属'
    ELSE 'ギルド所属'
  END
ORDER BY
  "カテゴリ";
```

ここで、`SELECT` 句には <span class="masked">`GROUP BY` 句で指定した CASE式 と同じ結果を返す式を記述する必要</span> があります。
- `GROUP BY` に指定していない式やカラムを (集約関数を適用せずに) `SELECT` に含めると、**グループ化されていないカラムの参照** とみなされ、エラーとなります。

実行結果は次のようになります。

```
  カテゴリ  | avg_lv | num
------------+--------+-----
 ギルド所属 |   52.1 |  14
 無所属     |   39.6 |   5
```

::: {.note .type-senior}
**EX: 整列順も厳密に制御したい場合は...**

`GROUP BY` 句に **CASE式** を使用したとき、整列順も厳密に制御したい場合は、次のようにします。

```sql{.numberLines caption="整列順を制御する例"}
SET
  search_path TO w03;

SELECT
  CASE
    WHEN guild IS NULL THEN 2
    ELSE 1
  END AS "ID", 
  CASE
    WHEN guild IS NULL THEN '無所属'
    ELSE 'ギルド所属'
  END AS "カテゴリ",
  ROUND(AVG(level), 1) AS "avg_lv",
  COUNT(*) AS "num"
FROM
  characters
GROUP BY
  CASE
    WHEN guild IS NULL THEN '無所属'
    ELSE 'ギルド所属'
  END,
  CASE
    WHEN guild IS NULL THEN 2
    ELSE 1
  END
ORDER BY
  CASE
    WHEN guild IS NULL THEN 2
    ELSE 1
  END;
```

実行結果は次のようになります。

```
 ID |  カテゴリ  | avg_lv | num
----+------------+--------+-----
  1 | ギルド所属 |   52.1 |  14
  2 | 無所属     |   39.6 |   5
```

:::

#### SQLドリル💻

- `ex-04_5.sql` 👉 **w03.characters** テーブルから、次のように前衛職と後衛職でグループをわけて最大レベル、平均レベル、人数を得る SQL を記述せよ。前衛職は Fighter、Monk、Samurai、Ninja、後衛職は Priest、Wizard とする。
  - 平均レベルは小数第2位を四捨五入して、小数第1位まで表示すること。

```
 battle_position | max_lv | avg_lv | num 
-----------------+--------+--------+-----
 backline        |     64 |   48.5 |   8
 frontline       |     73 |   49.1 |  11
```

### DATE_TRUNC関数を利用した時間軸に沿った集計処理

`GROUP BY` 句は、**時間軸に沿って集計処理** (日時でグループ化して集計処理) をしたい場面でも用いられます。この際、PostgreSQL では `DATE_TRUNC` 関数を利用することで SQL をシンプルに記述することができます。この関数は <span class="masked">指定した単位で日時を切り捨てる関数</span> で、次のように動作します。

- `DATE_TRUNC('hour', TIMESTAMP '2025-10-30 15:30:58')` 👉 `2025-10-30 15:00:00` (TIMESTAMP型)
- `DATE_TRUNC('month', TIMESTAMP '2025-10-30 15:30:58')` 👉 `2025-10-01 00:00:00` ( 〃 )
- `DATE_TRUNC('year', TIMESTAMP '2025-10-30 15:30:58')` 👉 `2025-01-01 00:00:00` ( 〃 )
    - 第1引数に指定可能な値 (文字列リテラル) は[公式ドキュメント](https://www.postgresql.org/docs/current/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC) を参照してください。
    - `DATE_TRUNC` は <span class="masked">標準SQLではなくPostgreSQL の独自関数 (拡張)</span> です。
    - 第2引数には `DATE` 型や `INTERVAL` 型をとることもできます。

たとえば、**最終ログイン日時** (`last_login_at`) を、月単位でまとめて、その件数を求めたいとき、`DATE_TRUNC` を利用すれば以下のように SQL を書くことができます。

```sql{.numberLines caption="最終ログイン日時の月別集計(1)"}
SET
  search_path TO w03;

SELECT
  DATE_TRUNC('month', last_login_at) AS "date", -- ◀ ここに注目
  COUNT(*) AS "num"
FROM
  characters
WHERE
  last_login_at IS NOT NULL
GROUP BY
  DATE_TRUNC('month', last_login_at) -- ◀ ここに注目
ORDER BY
  "date";
```

実行結果は、次のようになります。

```
        date         | num
---------------------+-----
 2025-07-01 00:00:00 |   4
 2025-08-01 00:00:00 |   4
 2025-09-01 00:00:00 |   6
 2025-10-01 00:00:00 |   4
```

体裁を整えたバージョンは以下のようになります。以下の SQL の **第05行目** の `TO_CHAR` 関数は、[第03回講義](lecture03.html#日付時刻関数を利用する)で紹介したように日時などを整形出力する関数です。

```sql{.numberLines caption="最終ログイン日時の月別集計(2)"}
SET
  search_path TO w03;

SELECT
  TO_CHAR(DATE_TRUNC('month', last_login_at), 'YYYY/MM') AS "date",
  COUNT(*) AS "num"
FROM
  characters
WHERE
  last_login_at IS NOT NULL
GROUP BY
  DATE_TRUNC('month', last_login_at)
ORDER BY
  "date";
```

実行結果は、次のようになります。

```
  date   | num
---------+-----
 2025/07 |   4
 2025/08 |   4
 2025/09 |   6
 2025/10 |   4
```

#### 参考: DATE_TRUNC関数を使用せずに同様の集計をする

`DATE_TRUNC` 関数を使用せずに、標準SQLで同様の処理をしたい場合には、**CASE式** で月ごとの区分を表現することができます。

```sql{.numberLines caption="最終ログイン日時の月別集計(DATE_TRUNC関数を不使用)"}
SET
  search_path TO w03;

SELECT
  CASE
    WHEN last_login_at >= DATE '2025-07-01' AND
    last_login_at < DATE '2025-08-01' THEN '2025/07'
    WHEN last_login_at >= DATE '2025-08-01' AND
    last_login_at < DATE '2025-09-01' THEN '2025/08'
    WHEN last_login_at >= DATE '2025-09-01' AND
    last_login_at < DATE '2025-10-01' THEN '2025/09'
    WHEN last_login_at >= DATE '2025-10-01' AND
    last_login_at < DATE '2025-11-01' THEN '2025/10'
    ELSE '(その他)'
  END AS "date",
  COUNT(*) AS "num"
FROM
  characters
WHERE
  last_login_at IS NOT NULL
GROUP BY
  CASE
    WHEN last_login_at >= DATE '2025-07-01' AND
    last_login_at < DATE '2025-08-01' THEN '2025/07'
    WHEN last_login_at >= DATE '2025-08-01' AND
    last_login_at < DATE '2025-09-01' THEN '2025/08'
    WHEN last_login_at >= DATE '2025-09-01' AND
    last_login_at < DATE '2025-10-01' THEN '2025/09'
    WHEN last_login_at >= DATE '2025-10-01' AND
    last_login_at < DATE '2025-11-01' THEN '2025/10'
    ELSE '(その他)'
  END
ORDER BY
  "date";
```

::: {.note .type-caution}
**日時の取り扱いに関する注意**

**last_login_at** がTIMESTAMP型のとき、`last_login_at BETWEEN DATE '2025-07-01' AND DATE '2025-07-31'` のような条件を記述すると、2025年07月31日の **00時00分00秒ちょうど** までしか含まれなくなるので注意してください。これは <span class="masked">`DATE '2025-07-31'` が `2025-07-31 00:00:00`</span> に変換されるためです。

そのため、**last_login_at** が <span class="masked">`2025-07-31 01:00:00`</span> のときは、その条件は **真にはならない** ので注意してください。

:::

#### SQLドリル💻

- `ex-04_6.sql` 👉 **w03.characters** テーブルについて、次のように **created_on** で年別に「人数」と「平均レベル」を集計した結果セットを得るような SQL を記述せよ。
  - 平均レベルは小数第2位を四捨五入して、小数第1位まで表示すること。

```
 year | num | avg_lv 
------+-----+--------
 2020 |   4 |   38.8
 2021 |   3 |   43.0
 2022 |   4 |   50.3
 2023 |   4 |   57.0
 2024 |   4 |   53.8
```

#### 定着確認

- あるテーブルの **guild** には、`A`、`A`、`B`、`NULL`、`NULL` の5件がある。`SELECT guild, COUNT(*) FROM テーブル名 GROUP BY guild;` の結果は何行になり、各グループの件数はいくつになるか答えよ。
  - **答え**: <span class="masked">3行。Aは2件、Bは1件、NULLは2件。NULLも1つのグループになる。</span>

- あるテーブルに、(guild, job) が (A, Fighter)、(A, Fighter)、(A, Wizard)、(NULL, Fighter) の4件がある。`GROUP BY guild, job` によってグループ化すると、グループ数はいくつになるか答えよ。
  - **答え**: <span class="masked">3グループ。AとFighterの組は2件、他の2組はそれぞれ1件。</span>

- **characters** テーブルには、**job** がFighterで **level** が10と20の2件がある。`SELECT job, level FROM characters GROUP BY job;` がエラーになる理由を答えよ。
  - **答え**: <span class="masked">1つのjobグループにlevelが10と20の複数の値があり、どのlevelを返すか決まらないため。levelにはMAXやAVGなどの集約関数を適用する。</span>

- PostgreSQL で `GROUP BY ROLLUP(guild)` を使用し、ギルド別集計と全体集計を得る。元データのguildがNULLのグループと、全体集計の行を区別するために `GROUPING(guild)` を取得した場合、それぞれの値を答えよ。
  - **答え**: <span class="masked">元データのguildがNULLのグループは0、全体集計の行は1。</span>

- PostgreSQL で `DATE_TRUNC('month', TIMESTAMP '2025-10-23 14:25:30')` を実行した結果を答えよ。
  - **答え**: <span class="masked">2025-10-01 00:00:00。月の先頭まで切り捨てられる。</span>

## HAVING 句

`GROUP BY` で **集約した結果を条件で絞り込みたい** ときは、`HAVING` 句を使用します。

- **集約前のレコード単体** に対して条件を指定したい場合は `WHERE` 句を使用します。

例えば、`GROUP BY guild` によって、所属ギルドごとにグループ化し、各グループの平均レベルが「50以上」のものだけを抽出したい場合は、`HAVING` 句を使って次のように SQL を記述します。

- `HAVING` 句では、集約関数を使わずに集約キー以外のカラムを直接参照することはできません。例えば `buff > 0.0` のような条件式は `HAVING` ではなく `WHERE` 句で指定します。

```sql{.numberLines caption="HAVING句の使用例"}
SET
  search_path TO w03;

SELECT
  COALESCE(guild,'Freelancer') AS "guild",
  COUNT(*) AS "num",
  ROUND(AVG(level), 1) AS "avg_lv"
FROM
  characters
GROUP BY
  guild
HAVING
  AVG(level) >= 50
ORDER BY
  AVG(level) DESC;
```

実行結果は、次のようになります。

```
 guild  | num | avg_lv
--------+-----+--------
 D.D.D  |   5 |   55.8
 hameln |   4 |   52.0
```

なお、`SELECT` 文は、`SELECT` 句 👉 `FROM` 句 👉 `WHERE` 句 👉 `GROUP BY` 句 👉 `HAVING` 句 👉 `ORDER BY` 句 👉 (`LIMIT` 句 / `OFFSET` 句) という順で記述しないと**構文エラー**になるので注意してください。

#### SQLドリル💻

- `ex-05_1.sql` 👉 **w03.characters** テーブルについて、次のようにジョブごとの「平均レベル」と「人数」を集計した結果セットを得る SQL を記述せよ。
  - 平均レベルは小数第2位を四捨五入して、小数第1位まで表示すること。
  - 人数が2名以下のジョブは結果セットに含めないこと。
  - 平均レベルの降順で表示すること。

```
   job   | avg_lv | num 
---------+--------+-----
 Samurai |   70.3 |   3
 Wizard  |   58.3 |   4
 Priest  |   38.8 |   4
 Fighter |   37.3 |   4
```

### WHERE句とHAVING句の使い分けについて

`HAVING` 句は、`GROUP BY` による <span class="masked">集約結果に対して条件を使った絞り込みをするため</span> に使用します。

また、`HAVING` 句では、集約キー以外のカラムは `COUNT` や `MAX` などの**集約関数を適用したうえで参照する必要**があります。例えば、`GROUP BY guild` のとき、`HAVING level >= 30` は指定できませんが、`HAVING MIN(level) >= 30` を指定することは可能です。

- 逆に言えば `WHERE` 句において、`COUNT` や `MAX` のような**「集約関数」を使用することはできません**。

#### 定着確認

- SQL において、次に示す各句を記述する適切な順序を記号で答えよ。
  - ➊ WHERE、❷ HAVING、❸ GROUP BY、❹ ORDER BY、❺ SELECT、❻ FROM
  - **答え** : <span class="masked">❺❻➊❸❷❹</span>


- **w03.characters** をjobごとに集計し、人数が3人以上のグループだけを残したい。GROUP BY句の後に記述するHAVING句を答えよ。
  - **答え**: <span class="masked">`HAVING COUNT(*) >= 3`</span>

- **w03.characters** の **level** はINTEGER型である。レベルが30以上のレコードだけを集計対象にしたい場合と、jobごとの平均レベルが50以上のグループだけを残したい場合に、それぞれ使用する句を答えよ。
  - **答え**: <span class="masked">前者はWHERE句（WHERE level >= 30）、後者はHAVING句（HAVING AVG(level) >= 50）。</span>

- **characters** テーブルには、Fighterがレベル20と60、Wizardがレベル40と60で各2件ずつ登録されている。`GROUP BY job HAVING AVG(level) >= 50` で残るjobと、その平均レベルを答えよ。
  - **答え**: <span class="masked">Wizardだけが残り、平均レベルは50。Fighterの平均は40なので残らない。</span>

- **characters** テーブルには、**guild** と **level** が存在する。`SELECT guild, COUNT(*) FROM characters WHERE COUNT(*) >= 3 GROUP BY guild;` の誤りを説明し、修正せよ。
  - **答え**: <span class="masked">WHERE句ではそのグループのCOUNT(*)を条件にできない。`SELECT guild, COUNT(*) FROM characters GROUP BY guild HAVING COUNT(*) >= 3;` とする。</span>

## 授業時間外学習の指示 (宿題)

🚨**本科目は「学修単位科目」であり、1回の講義あたり「4時間相当」の授業時間外学習が求められる科目です**🏃

- 次回の講義で「**小テスト❺**」を実施します。
  - **定着確認** および **SQLドリル** から主に出題します。
  - 講義が進行するにつれて、当然ながら小テストの内容も複雑で高度なものになっていきます。
- ここまでの第03回講義～第05回講義では、実践的な SQL について学んできました。次回講義では、データベースの**概念設計** (概念データモデルの設計) および**論理設計** (データモデルの設計) などの理論に寄せた内容を学んでいきます。
- 予習として📖 教科書「達人に学ぶDB設計 徹底指南書 (第2版)」の以下ページを読んできてください。内容が理解できなくても構いません。この予習の目的は <span class="masked">「ここがよく分からなかった」というポイントを自覚的に整理して、次回の授業に臨んでもらうこと</span> にあります。
  - 皆さんは既に PG3 で、複数テーブルから構成される DB を扱っているので、以下の順で読むほうが納得感があると思います。
  - pp.145-164 第4章「ER図」
      - 4-1 テーブルが多すぎる
      - 4-2 テーブル同士の関連を見抜く
      - 4-3 ER図の書き方
      - 4-4 「多対多」と関連実体
  - pp.89-123 第3章「論理設計と正規化」
      - 3-1 テーブルとは何か
      - 3-2 テーブルの構成要素
      - 3-3 正規化とは何か
      - 3-4 第1正規形
      - 3-5 第2正規形～部分関数従属
      - 3-6 第3正規形～推移的関数従属
  - pp.25-49 第2章「論理設計と物理設計」
      - 2-1 概念スキーマと論理設計
      - 2-2 内部スキーマと物理設計
      
---

- この講義資料を再読・熟読し「不明な用語」や「理解が不十分な用語」があればインターネットや、ChatGPTなどの生成AIを利用して解決してください。また、興味関心を持ったトピックについて、ウェブ、生成AI、YouTube動画などを利用して知識を広げ、理解を深めてください。
  - 特に **プロンプト例** を示しているものについては、実際に生成AIにプロンプトを投げ、さらに対話を重ねることで、知識の幅を広げるだけでなく、理解をより深く確かなものにしてください。
- 講義資料内の「**演習**」や「**SQLドリル**」に再度取り組んでください。特に、**SQLドリル**💻 は、授業時間中に1回取り組むだけでは定着しないので注意してください。
