---
var:
  header-title: "2026-4I データベース工学 第04回 講義資料"
  header-date: "2026年10月21日 (水) 1時限"
---

# 第04回 4I-データベース工学

## 連絡・授業概要など

### 連絡

- 小テスト❸ を実施します。
  - シラバス記載のように、小テストは最終評価の <span class="masked">35\%</span> に相当します。 
  - 遅刻・欠席等により追試験を希望する場合は [第01回講義で案内した手続き](lecture01.html#成績評価法と履修上の注意) をしてください。

- 今回の講義内容は、[前回講義](lecture03.html) の内容 ( ＝<span class="masked">演習環境における SQL の実行手順、基礎的な `SELECT` 文</span> ) を**ひととおり理解していること**を前提とします。まだ、それらの内容 (授業時間外学習のセクションを含む) を終えていない人は、まずは、そちらを終えてから取り組んでください。

### 今回の達成目標

- `ORDER BY`、`LIMIT`、`OFFSET` を使用して、取得するレコードの順序と範囲を指定できる。
- `WHERE` 句を使用して条件に一致するレコードを取得し、`NULL` を含む条件の評価結果を説明できる。
- `INSERT` 文によるレコードの挿入と、`ROLLBACK` による挿入の取消しを実行・確認できる。

## 準備

今回の講義 (授業時間外学習を含む) では、SQLの `ORDER BY` 句、`LIMIT` 句、`OFFSET` 句、`WHERE` 句、`INSERT` 文 について学んでいきます。

まずは、ハンズオン演習の準備として、以下の手順で、SQL 演習環境の動作確認、**教材の更新の取得**を実行してください。

### SQL演習環境の動作確認 (前回復習)

今回も、第03回で作成した **w03.users** と **w03.characters** という「テーブル」を利用していきます。

::: {.balloon .char-01 .face-02 .tone-yellow}
今回の演習で作成する SQL ファイルの先頭には、`SET search_path TO w03;` を記述してください。

`search_path` を設定すると、テーブル名などにスキーマ名を指定しなかった場合に、**w03** スキーマからテーブルが検索されるようになります。そのため、**w03.users** や **w03.characters** を、単に **users** や **characters** と記述できます。

ただし、`search_path` の設定は、現在のデータベース接続（セッション）に対して適用されます。この環境では、SQLファイルを実行するたびに新しい接続が確立されるため、使用するSQLファイルごとに、先頭で設定する必要があります。
:::

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL において、名前空間としての「スキーマ」とは何ですか？

> PostgreSQL において、`SET search_path TO ...;` はどのような意味を持ちますか。これを実行しないと、どのような振る舞いになりますか？ 

---

1. タスクトレイから **Docker Desktop** が起動していることを確認してください。
2. 前回講義で作成したプロジェクトフォルダ (講義資料のとおりに作成していれば **DB-PostgreSQL** ) を VSCode で開いてください。
3. VSCode のターミナルから `npm run db:up` を実行して **PostgreSQL と DbGate の2つのコンテナ** を起動してください。
4. [http://localhost:8080/](http://localhost:8080/) もしくは [http://127.0.0.1:8080/](http://127.0.0.1:8080/) から **DbGate** に接続して、**w03.users** テーブルと **w03.characters** テーブルが存在していることを確認してください。

::: {.balloon .char-01 .face-05 .tone-blue}

DbGate では、次の手順で、テーブルを参照します。

![img](figs/03/dbgate-01.png)

🚨「**Docker ボリュームを削除してしまった**」などの理由でテーブルが存在しないときは、VSCode のターミナルから、以下のコマンドを再実行して、テーブルの作成とレコードの挿入を行なってください。

- これらのコマンドを実行すると、**すでに存在するテーブルも含め、対象テーブルのデータが第03回の初期状態に戻ります**。

```bash
npm run sql from-teacher/03/init-users.sql
npm run sql from-teacher/03/init-characters.sql
```

::: 

5. VSCode で **sql/04/tmp.sql** を新規作成して、次の SQL 文を記述し、保存してください。

    ```sql{.numberLines caption="sql/04/tmp.sql"}
    SET
      search_path TO w03;

    SELECT * FROM users;
    ```

6. **sql/04/tmp.sql**  のエディタタブがアクティブな状態で `[Ctrl]+[Shift]+[B]` を押下して SQL を実行してください。もしくは VSCode のターミナルから以下のコマンドを入力して SQL を実行してください。

    ```bash
    npm run sql sql/04/tmp.sql
    ```

7. 次のような実行結果 (結果セット) が得られることを確認してください。

    ```
     id | name  | age 
    ----+-------+-----
      1 | Alice |  20
      2 | Bob   |  25
    ```


### 教材の更新の取得

[教材リポジトリ](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL) (＝皆さんが演習に使用するプロジェクトの `upstream`) が更新されています。次の手順で各自のローカルリポジトリに最新の変更を取り込んでください。

::: {.note .type-caution}
**注意** 

**更新の取り込み作業を始める前に、現在編集中のファイルはすべて保存し、全てコミットするか、スタッシュしておいてください。**

:::

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> Git では、リモートリポジトリからプルする前に、ローカルでの変更をコミットするか、スタッシュしておくように指示されました。これはなぜでしょうか。また、変更をコミットもスタッシュもせずにプルすると、どのような問題が起こる可能性があるのでしょうか。

VSCode のターミナルから以下のコマンドを実行してください。

```bash
git fetch upstream
```

```bash
git switch main
```

```bash
git merge upstream/main
```

最後の `git merge upstream/main` コマンドを実行すると、以下のようにマージコミットのメッセージについての編集画面が表示されることがあります。その場合は、内容を確認して「続行」ボタンを押してください。

![img](figs/03/git-01.png)

マージが完了したら、**MERGE_MSG** のタブは閉じて問題ありません。

以上の操作完了後、プロジェクトのなかに **from-teacher/04** というフォルダと、その内容 (SQLファイルなど) が追加されていることを確認してください。

## 教科書の演習に取り組むための環境設定

この授業では、**このウェブテキストをメインの教材として学習を進めます**。あわせて教科書も活用することで、同じ内容を異なる説明や例を通して学び、理解を深めることができます。また、ウェブテキストでは扱いきれない内容を補い、知識を広げることもできます。

::: {.balloon .char-01 .face-05 .tone-blue}
今回 (第04回講義) の学習内容は、教科書『SQL 第2版 ゼロからはじめるデータベース操作』の **第2章「検索の基本」(pp.43–78)** に対応しています。

ウェブテキストと並行して教科書を読み、掲載されている SQL 文を実際に記述・実行することで、学習内容への理解をさらに深めることができます。
:::


教科書に掲載されている SQL 文の動作確認や演習にも、この授業で構築した PostgreSQL 環境をそのまま利用できます。ただし、**演習に取り組む前に、教科書用のテーブルを作成しておく必要があります**。これらのテーブルは、授業で使用する他のテーブルと区別するため、**book** というスキーマ内に作成します。

教科書用のサンプルコードの入手・配置、テーブルの作成、各章の SQL を実行するための設定は [sql/README.md](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/sql/README.md) に手順をまとめています。教科書の演習に取り組む際は、この手順に従って環境を準備してください。

## ORDER BY 句

前回講義では、SQL の `SELECT` 文を使用して「**テーブルからレコードを取得する方法**」について学びました。その際、取得結果のレコードの **ならび (順番)** は、おそらく **id** カラムの昇順になっていたと思います。

実際に、**sql/04/tmp.sql** に以下の SQL 文を記述し、実行して結果を確認してください。

```sql{.numberLines caption="レコードの抽出"}
SET
  search_path TO w03;

SELECT
  id,
  guild AS "所属ギルド",
  name AS "名前",
  level AS "レベル",
  TO_CHAR(last_login_at, 'YYYY"/"MM"/"DD HH24":"MI') AS "最終ログイン"
FROM
  characters;
```

ここで押さえておくべき「**SQLの重要な特性**」があります。

SQL は「**集合指向**」の言語であり、「idカラムの昇順」あるいは「レコードが挿入(INSERT)された順」でレコードが得られるというのは <span class="masked">「たまたま」の結果</span> に過ぎません。実際には、取得結果のレコード (これを一般に「**結果セット** (**result set**)」とよびます) の「ならび (順序)」は **不定である** (**論理的に保証されるものではない**) ということを覚えておいてください。

そこで、**<u>指定した条件に従って結果セットを整列する仕組み</u>**として、`SELECT` 文には、`ORDER BY`句 というものが用意されています。

::: {.note .type-senior}
**中級者向け: 補足**

PostgreSQLはデータを **ヒープファイル（Heap File）** で管理しており、新しく追加された行は、通常、テーブル内の空きページや末尾のブロックに順次追加されます。そのため、テーブルスキャン (順次読み出し) を行うと、挿入順に近い順序で読み込まれることがよく起こります。ただし、`UPDATE` による行の更新、`VACUUM FULL` によるテーブルの書き直し、インデックススキャンの使用、並列処理などによって、取得結果の順序は変わることがあります。

そのため、`SELECT` 文の結果が、`INSERT` の順番に並ぶという挙動は「たまたま」そう見えているに過ぎず、**結果セットのレコード順序を意図的に制御したい場合は必ず** `ORDER BY` **句を使用**する必要があります。

- ここでの **ヒープファイル** とは、アルゴリズムやデータ構造で学んだ ヒープ構造 (二分ヒープなど) とは**全く別物**です。データを「積み上げる（Heap）」ことに由来する用語で、特定のデータ構造を指すものではないので注意してください。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL における `VACUUM` とは何ですか。

:::

### ORDER BY 句

`ORDER BY` は、`SELECT` 文において、結果セットのレコードの「**ならび** (**順序**)」を指示するもので (＝<span class="masked">整列順・ソート順</span> を指示するもので)、以下のように `FROM` 句 **より後**に記述します。

`ORDER BY` が指定するのは、**取得結果のならび**であり、元のテーブルのデータを、<u>この順序に並べ替えて保存するわけではない</u> ので注意してください。

```sql{.numberLines caption="結果セットをguildカラムの値で整列"}
SET
  search_path TO w03;

SELECT
  id,
  guild AS "所属ギルド",
  name AS "名前",
  level AS "レベル",
  TO_CHAR(last_login_at, 'YYYY"/"MM"/"DD HH24":"MI') AS "最終ログイン"
FROM
  characters
ORDER BY -- ◀ ここに注目
  guild;
```

- `SELECT` 文は、`SELECT` 句 👉 `FROM` 句 👉 `ORDER BY` 句 という順序で記述しないと**構文エラーになる**ので注意してください。

上記の SQL の実行結果 ( `ORDER BY guild` の結果) は、「**所属ギルド**」を基準に整列されます。以下に実行結果の一例を示します。文字列の具体的な整列順は、後述する「**照合順序**」の設定によって変わる場合があります。

```
 id | 所属ギルド |  名前   | レベル |   最終ログイン   
----+------------+---------+--------+------------------
 17 | D.D.D      | Wendy   |     56 | 2025/08/08 10:56
 13 | D.D.D      | Mallet  |     64 | 2025/08/27 18:50
  2 | D.D.D      | Zach    |     62 | 2025/07/30 18:33
 14 | D.D.D      | Eve     |     46 | 2025/10/07 10:17
 11 | D.D.D      | Ellen   |     51 | 2025/09/25 23:55
  1 | Yamato     | Marvin  |     35 | 2025/07/24 13:31
 12 | Yamato     | Dave    |     68 | 2025/08/15 16:08
 15 | Yamato     | Trent   |     50 | 2025/10/11 17:20
 ～～ 以下略 ～～
```

::: {.balloon .char-01 .face-02 .tone-yellow}
ここでは、所属ギルドの順序だけを指定しています。

**同じギルドに所属するキャラクタ同士のならびは、まだ指定していません**。ギルド内のならびも指定する方法は、このあとの「複数のソートキーの指定」で説明します。
:::

`ORDER BY` は、デフォルトで `ASC` (＝ <span class="masked">昇順</span>) で整列 (ソート) します。数値型なら「小さい順」、日時型なら「古い順」になります。

降順に整列したい場合は、`ORDER BY guild DESC` のように <span class="masked">`DESC` キーワード</span> を指定します。

- 昇順であることを明示したい場合は `ORDER BY guild ASC` のようにします。
- PostgreSQL では、昇順 ( `ASC` ) で整列した場合、`NULL` 値は <span class="masked">最後に配置</span> されることに注意してください。
- 文字列の整列順は、データベースなどに設定された **照合順序 (Collation)** によって変わります。「大文字の `A-Z` が先、小文字の `a-z` が後」という順序に、常になるわけではありません。
  - 大文字と小文字を区別せずに整列したい場合は、ここでは `ORDER BY LOWER(guild)` のように、小文字に変換した値を整列の基準にします。

::: {.note .type-senior}
**中級者向け: 演習環境における照合順序 (文字列の整列順) の確認**

PostgreSQL においては、照合順序は、**文字列型のカラムごとに設定**することができます。カラムに個別の指定がなければ、データベース既定の照合順序が使用されます。

実際に、`ORDER BY guild` に適用される照合順序と、それによる文字列の整列順を確認してみます。**sql/04/temp.sql** に次の SQL を記述し、実行してみてください。最後の `VALUES` は、確認用の文字列を用意するための記法となります。

```sql{.numberLines caption="sql/04/temp.sql"}
SELECT DISTINCT COLLATION FOR (guild) AS collation
FROM w03.characters;

SELECT datcollate
FROM pg_database
WHERE datname = current_database();

SELECT word
FROM (VALUES ('b'), ('A'), ('a'), ('B'),
             ('い'), ('ぃ'), ('あ'), ('ぁ'),
             ('が'), ('か'), ('ぱ'), ('ば'), ('は'),
             ('山田'), ('田中')) AS sample(word)
ORDER BY word;
```

最初の結果は `"default"` となり、これより **guild カラムにはデータベース既定の照合順序が適用されている**ことが確認できます。

つづいての結果は `ja_JP.UTF-8` であり、**この演習環境における、データベース既定の照合に使用するロケール**が **ja_JP.UTF-8** であることが確認できます。

最後の SQL で、**ja_JP.UTF-8** による整列順を確認しています。これより以下のようなことがわかると思います。

- **アルファベット**: 大文字の `A`〜`Z` が先、そのあとに小文字の `a`〜`z` がならびます。
- **ひらがな**: 小さい文字と通常の文字は、「ぁ」👉「あ」👉「ぃ」👉「い」の順で並びます。濁点・半濁点を含む例では、「か」👉「が」、「は」👉「ば」👉「ぱ」の順で並びます。
- **漢字**: より複雑で、単純に読みの五十音順にはなりません。この環境では「山田」が「田中」より先になります。なお、**単純な UTF-8 の文字コード順になるわけではない**ことに注意してください。

漢字氏名を読み順にならべたい場合は、「ふりがな」のカラムを別に用意し、その値を基準に整列することが一般的となります。
:::

#### 演習

- `ORDER BY guild DESC` としたとき、`NULL` 値は「最初に配置される」か「最後に配置される」かを確認してください。
- `ORDER BY LOWER(guild)` としたとき、「D.D.D」👉「hameln」👉「Yamato」👉「(NULL)」のように整列されることを確認してください。
- レベルが低いキャラから順番に結果セットが整列されるように (＝レベルの昇順に) SQL を書き換えてください。
- レベルが高いキャラから順番に結果セットが整列されるように (＝レベルの降順に) SQL を書き換えてください。
- 最終ログインが最近のキャラから順番に結果セットのレコードがならぶように SQL を書き換えてください。また、最終ログイン日時が `NULL` のキャラが、どこに配置されたかも確認してください。

#### 定着確認

- **users** というテーブルに、**name** ( `VARCHAR(16)` 型) というカラムが存在している。`SELECT` 文において、**name** を ABC順 (例えば、Alice👉Bob👉Carol👉Charlie👉...のような順) にデータをならべたい。どのように `ORDER BY` 句を記述すればよいか答えよ。
  - **答え**: <span class="masked">`ORDER BY name ASC` もしくは `ORDER BY name`</span>
- **users** というテーブルに、**name** ( `VARCHAR(16)` 型) というカラムが存在し、英字の大文字と小文字が混在している。`SELECT` 文において、大文字と小文字を区別せずに **name** の昇順で整列したい。`LOWER` 関数を使用して、`ORDER BY` 句を記述せよ。
  - **答え**: <span class="masked">`ORDER BY LOWER(name) ASC` もしくは `ORDER BY LOWER(name)`</span>
- **users** というテーブルに、**age** ( `INTEGER` 型) というカラムが存在し、`NULL` は含まれていない。`SELECT` 文において、**age** カラムを参照して年齢が高いユーザから順にデータをならべたい。どのように `ORDER BY` 句を記述すればよいか答えよ。
  - **答え**: <span class="masked">`ORDER BY age DESC` </span>
- **users** というテーブルに、誕生日を保持する **birthday** ( `DATE` 型) というカラムが存在している。`SELECT` 文において、誕生日順 (過去👉現在) にデータをならべたい。どのように `ORDER BY` 句を記述すればよいか答えよ。
  - **答え**: <span class="masked">`ORDER BY birthday` もしくは `ORDER BY birthday ASC`</span>
- PostgreSQL で `NULLS FIRST` や `NULLS LAST` を指定せず、`ORDER BY` により昇順に整列 (ソート) したとき、`NULL` 値は「最初に配置される」か「最後に配置される」かを答えよ。
  - **答え**: <span class="masked">最後に配置される</span>
- 一般に `ASC` は「昇順」と「降順」のどちらを意味するか答えよ。
  - **答え**: <span class="masked">昇順</span>
- `ORDER BY` 句において `ASC` や `DESC` を明示しないとき、デフォルト動作としては「昇順」と「降順」のどちらになるか答えよ。
  - **答え**: <span class="masked">昇順</span>

- `SELECT` 文において、`FROM` 句、`ORDER BY` 句、`SELECT` 句の3つを、SQL文に記述する順序に並べよ。
  - **答え**: <span class="masked">`SELECT` 句 👉 `FROM` 句 👉 `ORDER BY` 句</span>

- PostgreSQL の **w03.users** テーブルには、**id** と **name** というカラムが存在する。次の SQL 文には、句の記述順序に誤りがある。**name** の昇順で **id** と **name** を取得できるように、SQL文を修正せよ。
  - **答え**: <span class="masked">`FROM` 句を `ORDER BY` 句の前に移動する。`SELECT id, name FROM w03.users ORDER BY name;`</span>  
```sql{.numberLines caption="定着確認"}
SELECT
    id,
    name
ORDER BY
    name
FROM
    w03.users;
```

### 複数のソートキーの指定

`ORDER BY` 句では、**カンマで区切って**、第1ソートキー、第2ソートキー、第3ソートキー...と複数のソートキーが指定できます。例えば、まず **所属ギルドのABC順 (昇順) で整列** し、さらに **所属ギルドのなかでレベルが高い順 (降順) に整列** したい場合は、次の **第12行目** のように `ORDER BY` 句を記述します。

```sql{.numberLines caption="複数のソートキーを指定"}
SET
  search_path TO w03;

SELECT
  id,
  guild AS "所属ギルド",
  name AS "名前",
  level AS "レベル",
  TO_CHAR(last_login_at, 'YYYY"/"MM"/"DD HH24":"MI') AS "最終ログイン"
FROM
  characters
ORDER BY -- ◀ ここに注目
  guild,
  level DESC;
```

ソートキーは、**左から順に優先**されます。この例では、まず `guild` で整列し、**guild の値が同じレコード同士を、level の降順で整列**します。

- 明示的に `ORDER BY guild ASC, level DESC;` としても同様の結果となります。
- `ASC` や `DESC` は、それぞれのソートキーに対して指定します。`ORDER BY guild, level DESC` の `DESC` が適用されるのは、**level だけ**です。
 
実際に実行して結果を確認してみてください。

#### SQLドリル💻

- `ex-01_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。整列の基準は、第1キーを **job** (昇順)、第2キーを **level** (降順)、第3キーを **name** (昇順) とすること。

```
 id |   job   | level |  name   
----+---------+-------+---------
 17 | Fighter |    56 | Wendy
  7 | Fighter |    48 | Trudy
 10 | Fighter |    44 | Oscar
  4 | Fighter |     1 | Tom
  5 | Monk    |    39 | Ivan
  8 | Monk    |    33 | Bob
  2 | Ninja   |    62 | Zach
 14 | Ninja   |    46 | Eve
 ～～ 以下略 ～～
```

- `ex-01_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。整列の基準は、第1キーを **guild** (昇順・大文字と小文字を区別しない)、第2キーを **level** (降順) とすること。

```
 id | guild  | Lv. |    name (job)    
----+--------+-----+------------------
 13 | D.D.D  |  64 | Mallet (Wizard)
  2 | D.D.D  |  62 | Zach (Ninja)
 17 | D.D.D  |  56 | Wendy (Fighter)
 11 | D.D.D  |  51 | Ellen (Wizard)
 14 | D.D.D  |  46 | Eve (Ninja)
 16 | hameln |  70 | Steve (Samurai)
 19 | hameln |  61 | Jack (Wizard)
 ～～ 中略 ～～
  1 | Yamato |  35 | Marvin (Priest)
  9 |        |  73 | Walter (Samurai)
  3 |        |  57 | Charlie (Wizard)
  5 |        |  39 | Ivan (Monk)
 18 |        |  28 | Carol (Priest)
  4 |        |   1 | Tom (Fighter)
```

### NULL 値のソート位置を指定

先のセクションで確認したように、PostgreSQL では `NULL` の位置を明示せずに `ORDER BY` に `ASC` (昇順) を指定した場合、`NULL` 値は最後に配置されます。逆に `DESC` (降順) を指定した場合は、`NULL` 値が先頭に配置されます。


::: {.balloon .char-01 .face-04 .tone-blue}
`NULLS FIRST`・`NULLS LAST` を **省略した場合** の `NULL` の位置は、DBMS (PostgreSQL, MySQL, SQLite, Oracle etc.) によって異なります。これは
実装依存 (implementation-dependent) であり、使用する DBMS の仕様によって決まるという意味です。
:::

標準 SQL (および PostgreSQL を含む多くの実装) では、`ORDER BY` による整列で `NULL` の位置を明示的に指定するために `NULLS LAST` と `NULLS FIRST` というキーワードが使用できます。

例えば、次のように記述することで、最終ログイン日時が新しい順 (降順 `DESC`) に並べつつ、`NULL` 値のレコードを「最後」に配置することができます。

```sql{.numberLines caption="NULLを末尾に配置"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  last_login_at
FROM
  characters
ORDER BY
  last_login_at DESC NULLS LAST; -- ◀ ここに注目
```

`NULLS FIRST`・`NULLS LAST` は、各ソートキーの `ASC`・`DESC` の **後ろ** に記述してください。例えば、`ORDER BY LOWER(guild) ASC NULLS FIRST, level ASC` では、ギルドが `NULL` のレコードを先頭にまとめ、そのなかではレベルの昇順に整列します。

- 上記の **第11行目** を `last_login_at DESC;` に書き換えると、`last_login_at` が `NULL` のレコードが先頭に配置されることを確認してください。

#### 定着確認

- `ORDER BY` 句で整列順を指示する際に `NULL` 値を先頭に配置したい。どのようなキーワードを使用すればよいか答えよ。
  - **答え**: <span class="masked">`NULLS FIRST` (`NULL` ではなく `NULLS` である点に注意)</span>
- `ORDER BY` 句で整列順を指示する際に `NULL` 値を末尾に配置したい。どのようなキーワードを使用すればよいか答えよ。
  - **答え**: <span class="masked">`NULLS LAST`</span>


#### SQLドリル💻

- `ex-02_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。整列の基準は、第1キーを **guild** (昇順・大文字と小文字を区別しない・`NULL` は先頭)、第2キーを **level** (昇順) とすること。  
```
 id |  name   | level | guild  
----+---------+-------+--------
  4 | Tom     |     1 |
 18 | Carol   |    28 |
  5 | Ivan    |    39 |
  3 | Charlie |    57 |
  9 | Walter  |    73 |
 14 | Eve     |    46 | D.D.D
 11 | Ellen   |    51 | D.D.D
 17 | Wendy   |    56 | D.D.D
  2 | Zach    |    62 | D.D.D
 13 | Mallet  |    64 | D.D.D
  8 | Bob     |    33 | hameln
 10 | Oscar   |    44 | hameln
 ～～以下略～～
```

- `ex-02_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、並び順は **last_login_at** が新しい順 (降順・`NULL` は末尾) となるようにし、**Days Since Last Login** カラムは「2025/10/15」を基準日として、最終ログインが何日前かを出力すること。
  - ヒント: 前回講義 [現在日時と日数・時間の差を計算する](lecture03.html#現在日時と日数時間の差を計算する)
  - 日数は、`last_login_at` を `DATE` 型に変換し、基準日との日付の差として求めること。

```
 id |  name   |    last_login_at    | Days Since Last Login 
----+---------+---------------------+-----------------------
 15 | Trent   | 2025-10-11 17:20:00 | 4 days ago
 14 | Eve     | 2025-10-07 10:17:00 | 8 days ago
 16 | Steve   | 2025-10-06 09:14:00 | 9 days ago
 18 | Carol   | 2025-10-03 11:42:00 | 12 days ago
  7 | Trudy   | 2025-09-29 12:37:00 | 16 days ago
 11 | Ellen   | 2025-09-25 23:55:00 | 20 days ago
  6 | Alice   | 2025-09-18 14:22:00 | 27 days ago
 ～～ 中略 ～～
  3 | Charlie | 2025-07-29 20:37:00 | 78 days ago
  1 | Marvin  | 2025-07-24 13:31:00 | 83 days ago
  5 | Ivan    | 2025-07-18 19:29:00 | 89 days ago
  4 | Tom     |                     |
```

### CASE式を使用したORDER BY句の指定

前回講義では、`SELECT` 句のなかで [CASE式](lecture03.html#case-式を利用する) を利用する方法を紹介しました。`CASE` 式は `SELECT` 句だけではなく `ORDER BY` 句のなかでも使用することができます。

::: {.balloon .char-01 .face-02 .tone-yellow}
SQL文のなかで「式」を記述できる場所であれば、どこでも `CASE` 式を記述することができます。
:::

例えば、**job**カラムについて、「**後衛職**」👉「**前衛職**」の順に整列し、さらに、それぞれのなかでは「ABC順」にジョブ (職業) を整列し、さらにレベル (降順) で整列したい場合は、次のように `ORDER BY` 句のなかで `CASE` 式を利用します。

- **後衛職**: `Priest`、`Wizard`
- **前衛職**: `Fighter`、`Monk`、`Ninja`、`Samurai`

```sql{.numberLines caption="CASE式を利用した整列"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  job,
  level
FROM
  characters
ORDER BY
  CASE
    WHEN job = 'Priest' OR job = 'Wizard' THEN 1
    ELSE 2
  END ASC, -- CASE式による第1キー
  job, -- 第2キー
  level DESC; -- 第3キー
```

ここでは、**第12行目** から **第15行目** にかけての `CASE` 式で後衛職に数値の「**1**」、それ以外 (前衛職) に数値の「**2**」を割り当て、それを第1キーとして昇順 (`ASC`) に整列しています。つまり、ジョブ (文字列型) を数値型にマッピングして、それを整列のキーに使用しています。

この `CASE` 式が返す「1」「2」は整列のために使用され、結果セットには表示されません。元の **job** カラムの値も変更されません。

- **第13行目** は、`IN` キーワードを使用して `WHEN job IN ('Priest', 'Wizard') THEN 1` のように記述することもできます。

実行結果は、次のようになります。

```
 id |  name   |   job   | level 
----+---------+---------+-------
 15 | Trent   | Priest  |    50
  6 | Alice   | Priest  |    42
  1 | Marvin  | Priest  |    35
 18 | Carol   | Priest  |    28
 13 | Mallet  | Wizard  |    64
 19 | Jack    | Wizard  |    61
  3 | Charlie | Wizard  |    57
 11 | Ellen   | Wizard  |    51
 17 | Wendy   | Fighter |    56
  7 | Trudy   | Fighter |    48
  ～～ 中略 ～～
 16 | Steve   | Samurai |    70
 12 | Dave    | Samurai |    68
```

レベルの降順が適用されるのは、同じ職業のレコード同士です。例えば、**Carol** (`Priest`・レベル28) が **Mallet** (`Wizard`・レベル64) より先に配置されるのは、レベルよりも職業の整列順が優先されるためです。

#### SQLドリル💻

- `ex-03_1.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、ギルドのならびが「Yamato」、「`NULL`(無所属)」、それ以降は大文字と小文字を区別しない昇順 (ABC順) となるようにすること。また、各ギルド内ではレベルの降順で並ぶようにすること。
  - ヒント: `NULL` を `(無所属)` という文字列で出力するためには、[前回講義](lecture03.html#nullを別の値に変換する) で紹介した <span class="masked">`COALESCE`</span> を利用する。
  - `CASE` 式の条件で **guild** が `NULL` かどうかを判定するときは、`= NULL` ではなく `IS NULL` を使用すること。

```
 id |  name   | level |  guild   
----+---------+-------+----------
 12 | Dave    |    68 | Yamato
 15 | Trent   |    50 | Yamato
  7 | Trudy   |    48 | Yamato
  6 | Alice   |    42 | Yamato
  1 | Marvin  |    35 | Yamato
  9 | Walter  |    73 | (無所属)
  3 | Charlie |    57 | (無所属)
  5 | Ivan    |    39 | (無所属)
 18 | Carol   |    28 | (無所属)
  4 | Tom     |     1 | (無所属)
 13 | Mallet  |    64 | D.D.D
  2 | Zach    |    62 | D.D.D
 17 | Wendy   |    56 | D.D.D
 11 | Ellen   |    51 | D.D.D
 14 | Eve     |    46 | D.D.D
 16 | Steve   |    70 | hameln
 19 | Jack    |    61 | hameln
 10 | Oscar   |    44 | hameln
  8 | Bob     |    33 | hameln
```

- `ex-03_2.sql` 👉 **w03.characters** テーブルのすべてのレコードについて、次に示すようなカラムを出力する SQL を記述せよ。なお、第1キーを **job** (カスタム順: Samurai、Ninja、Fighter、Monk、Priest、Wizard の順)、第2キーを **level** (降順) とすること。

```
 id |  name   | level |   job   
----+---------+-------+---------
  9 | Walter  |    73 | Samurai
 16 | Steve   |    70 | Samurai
 12 | Dave    |    68 | Samurai
  2 | Zach    |    62 | Ninja
 14 | Eve     |    46 | Ninja
 17 | Wendy   |    56 | Fighter
 ～～ 中略 ～～
 18 | Carol   |    28 | Priest
 13 | Mallet  |    64 | Wizard
 19 | Jack    |    61 | Wizard
  3 | Charlie |    57 | Wizard
 11 | Ellen   |    51 | Wizard
```

## LIMIT 句

SQL では、`LIMIT` を使用して <span class="masked">取得するレコードの上限</span> を設定することができます。

- `SELECT` 文は、`SELECT` 句 👉 `FROM` 句 👉 `ORDER BY` 句 👉 `LIMIT` 句 という順で記述しないと構文エラーになるので注意してください。

例えば、レベルの高い順に整列して「**上位5件**」のレコードを取得する場合、次のように SQL を記述します。

```sql{.numberLines caption="LIMITの活用"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  level
FROM
  characters
ORDER BY
  level DESC
LIMIT -- ◀ ここに注目
  5;
```

`LIMIT 30` のように、全レコード数よりも大きな値を指定するとどのようになるか、実際に確認してください。

### LIMIT の利用上の注意点

`LIMIT` 句は単独でも使用できますが、実務では `ORDER BY` 句と組み合わせて使うことが基本となります。`ORDER BY` 句なしで `LIMIT` 句を使用すると、その結果セットの内容は「**不定**」となります。

- `ORDER BY` なしでも毎回同じ結果セットが得られるように見えることがありますが、それは <span class="masked">偶然にすぎず、保証された動作ではありません</span>。

実運用では、`VACUUM FULL` によるテーブルの書き直しや `UPDATE`、インデックスの利用状況、**並列実行の影響**などで、**取得されるレコードの順序が変化する可能性があり**、そこから上位 N 件分を取得する `LIMIT` の結果も変わります。


::: {.balloon .char-01 .face-02 .tone-yellow}

意図的に「**N 件のレコードをランダムに取得したい**」という場合には、次のように `ORDER BY RANDOM()` と `LIMIT` を併用します。

```sql{.numberLines caption="ランダムに5件のレコードを取得"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  level
FROM
  characters
ORDER BY
  RANDOM() -- ◀ ここに注目
LIMIT
  5;
```

これにより、<u>ランダムに5件のレコードを取得すること</u> ができます。
:::

::: {.note .type-caution}
**ORDER BY を指定しても、同値の行同士の順序には注意**

`ORDER BY level DESC` のように整列していても、同じレベルのレコード同士の順序は保証されないので注意してください。そのため、**<u>同値のレコードがページの境界をまたぐ場合、ページごとに取得すると、同じレコードが重複したり、一部のレコードを取得し損ねたりする可能性</u>**があります。

- 同じデータに対して順序を一意に定めるには、`ORDER BY level DESC, id ASC` のように、主キーの **id** など一意な値を持つカラムを最後のソートキーに追加します。

より詳しく知りたい人は [PostgreSQL 18 公式資料の「SELECT」の ORDER BY Clause](https://www.postgresql.org/docs/18/sql-select.html) と [LIMIT and OFFSET](https://www.postgresql.org/docs/18/queries-limit.html) を参照してください。前者にはすべてのソートキーが同値の場合の扱い、後者には順序を一意に定める必要性が説明されています。
:::

### OFFSET 句

`LIMIT` と `OFFSET` を組み合わせて使用することで「**ページング処理** (**ページネーション**)」を行なうことができます。たとえば、ある結果セットについて「**101件目から150件目**」だけを取得したいとき、`LIMIT 50 OFFSET 100` のように利用することができます。`OFFSET 100` は先頭の100件を読み飛ばす指定であり、その次の101件目から、最大50件を取得します。

ただし、`OFFSET` で読み飛ばす行も、<span class="masked">サーバ内部では処理する必要があります</span>。そのため、大きなオフセット値は**処理負担が増える原因**になります。

- 例えば、同じ条件で `LIMIT 50 OFFSET 100` と `LIMIT 50 OFFSET 10000` を比較すると、一般的には後者のほうが処理負担が大きくなります。ただし、実際のレスポンスタイムはデータや実行計画などにも左右されます。

::: {.balloon .char-01 .face-02 .tone-yellow}

大きなオフセット値による応答時間の増加が問題になる場合は、「**カーソルページネーション** (**キーセットページネーション**)」という手法も検討します。

これは、最後に表示したレコードのキーを基準に、その次のレコードから取得する手法です。例えば、**id** の昇順で次のページへ進む場合は、`WHERE id >【最後に表示したID】 ORDER BY id ASC LIMIT 50` のように記述します。降順で進む場合は、`WHERE id <【最後に表示したID】 ORDER BY id DESC LIMIT 50` となります (`WHERE` 句は、このあとのセクションで説明します)。

この手法は、整列順と検索条件に合ったインデックス (詳細は次回以降に説明) を利用できる場合、**大きな `OFFSET` による処理負担を抑えることができます**。採用するかどうかは、レコード数だけでなく、取得条件や実際の応答時間を踏まえて判断します。

ただし、カーソルページネーションは、前のページの最後のキーを基準にするため、<span class="masked">特定のページ番号に直接ジャンプすることができない</span> というデメリットがあります。

:::

以下に「**レベルの降順で整列して、11件目から15件目にあたるレコードを取得する SQL**」を示します。

```sql{.numberLines caption="OFFSETとLIMITの利用"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  level
FROM
  characters
ORDER BY
  level DESC
LIMIT
  5
OFFSET -- ◀ ここに注目
  10;
```

- `LIMIT 5 OFFSET 10` は、順番を入れ替えて `OFFSET 10 LIMIT 5` としても問題ありません (構文エラーにはなりません)。
  - ただし、一般的には `LIMIT ... OFFSET ...` で記述します。PostgreSQL の公式ドキュメントでも、この順序で記載されています。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> ウェブアプリに関する文脈で「ページング処理」とはなんですか。

> RDBに関する文脈で「カーソルページネーション」とは何ですか。

> RDBに関する文脈で「インデックス」とは何ですか。「カーソルページネーションは、整列順と検索条件に合ったインデックスを利用できると、大きな `OFFSET` を与えたときの処理負担を抑えることができます」と言われたのですが、どういうことですか？

#### SQLドリル💻

- `ex-04_1.sql` 👉 **w03.characters** テーブルから、**id**、**name**、**job**、**level** の 4 つのカラムを持つレコードをランダムに3件取得する SQL を記述せよ。

- `ex-04_2.sql` 👉 **w03.characters** テーブルから、**last_login_at** が古い順に5件のレコードについて、以下のようなカラムを取得する SQL を記述せよ。なお、**last_login_at** が `NULL` であるレコード (＝アカウント作成後、一度もログインされていないもの) も含めて、先頭に配置すること。

```
 id |  name   |    last_login_at    
----+---------+---------------------
  4 | Tom     |
  5 | Ivan    | 2025-07-18 19:29:00
  1 | Marvin  | 2025-07-24 13:31:00
  3 | Charlie | 2025-07-29 20:37:00
  2 | Zach    | 2025-07-30 18:33:00
```

- `ex-04_3.sql` 👉 **w03.characters** テーブルから、**created_on** を古い順 (`NULL`は末尾) にならべて「11件目から15件目」にあたるレコードを、以下のようなカラムで取得する SQL を記述せよ。

```
 id |  name  | created_on 
----+--------+------------
 10 | Oscar  | 2022-11-10
 12 | Dave   | 2023-01-19
 13 | Mallet | 2023-02-02
 14 | Eve    | 2023-09-07
 15 | Trent  | 2023-10-04
```

- 注意: **w03.characters** テーブルの Oscar (id: `10`) と Ellen (id: `11`) の **created_on** は、`from-teacher/03/init-characters.sql` のなかで意図的に逆転させています。

#### 定着確認

- **w03.characters** テーブルには19件のレコードが存在する。`SELECT * FROM w03.characters LIMIT 5;` を実行したとき、結果セットの件数と、実行後の元テーブルのレコード数をそれぞれ答えよ。
  - **答え**: <span class="masked">結果セットは5件、元テーブルは19件。`LIMIT` は取得件数の上限を指定するものであり、元テーブルのレコードを削除しない。</span>

- **w03.characters** テーブルには19件のレコードが存在する。`SELECT * FROM w03.characters LIMIT 30;` を実行したとき、結果セットは何件になるか答えよ。
  - **答え**: <span class="masked">19件。`LIMIT 30` は最大30件の指定であり、対象のレコードが19件であれば19件だけが返される。</span>

- PostgreSQL の `SELECT` 文で、`SELECT` 句・`FROM` 句・`ORDER BY` 句・`LIMIT` 句の4つを使用する。これらを SQL に記述する順に並べよ。
  - **答え**: <span class="masked">`SELECT` 句 👉 `FROM` 句 👉 `ORDER BY` 句 👉 `LIMIT` 句</span>

- **w03.characters** テーブルの **id** は主キーであり、1から19までの整数が1件ずつ存在する。`SELECT id FROM w03.characters ORDER BY id ASC LIMIT 5 OFFSET 10;` を実行したとき、取得される **id** を表示順に答えよ。
  - **答え**: <span class="masked">11、12、13、14、15。先頭の10件を読み飛ばしたあと、5件を取得する。</span>

- **w03.characters** テーブルの **id** は主キーであり、1から19までの整数が1件ずつ存在する。`SELECT id FROM w03.characters ORDER BY id ASC LIMIT 5 OFFSET 17;` を実行したとき、取得される件数と **id** を答えよ。
  - **答え**: <span class="masked">2件で、idは18と19。先頭の17件を読み飛ばすと2件しか残っていないため、5件は返されない。</span>

- あるテーブルにおいて、**updated_at** カラムを降順でソートしたとき、251件目から300件目のレコードだけを取得したい。`LIMIT` 句 と `OFFSET` 句をどのように与えればよいか答えよ。
  - **答え**: <span class="masked">`LIMIT 50 OFFSET 250`</span>
- 大量のデータを一度にすべて表示するのではなく、`LIMIT` 句と `OFFSET` 句を組み合わせて「1ページ目」「2ページ目」のように小分けにして取得・表示する処理を何というか。
  - **答え**: <span class="masked">「ページング処理」または「ページネーション」</span>

- `LIMIT 50 OFFSET 100` と `LIMIT 50 OFFSET 10000` を比較したとき、そのレスポンスタイムは、一般的に【　　　】。括弧にあてはまる語を「変わらない」「前者のほうが大きい」「後者のほうが大きい」から選び答えよ。
  - **答え**: <span class="masked">後者のほうが大きい</span>

- **w03.characters** テーブルからランダムに5件を取得する方法として、`SELECT * FROM w03.characters LIMIT 5;` は適切か。理由とともに答えよ。
  - **答え**: <span class="masked">適切ではない。`ORDER BY` を省略した場合の順序は保証されず、ランダムに選ばれるという保証もない。</span>

- **w03.characters** テーブルには19件のレコードが存在する。ランダムに3件のレコードを取得するため、`SELECT * FROM w03.characters` に続ける `ORDER BY` 句と `LIMIT` 句を記述せよ。
  - **答え**: <span class="masked">`ORDER BY RANDOM() LIMIT 3;`</span>

- 仮の **characters** テーブルには、主キーの **id** (`INTEGER` 型) と **level** (`INTEGER` 型) があり、同じレベルのレコードが複数存在する。`ORDER BY level DESC LIMIT 5` と指定すれば、同じデータに対して、同じレベルのレコード同士の順序も保証されるか。保証されない場合は、順序を一意に定める `ORDER BY` 句を記述せよ。
  - **答え**: <span class="masked">保証されない。`ORDER BY level DESC, id ASC` のように、主キーのidを最後のソートキーに追加する。</span>

- ページング処理において、`OFFSET` で先頭から一定件数を読み飛ばす代わりに、前のページで最後に表示したレコードのキーを基準として、その次のレコードから取得する手法を何というか。
  - **答え**: <span class="masked">「カーソルページネーション」または「キーセットページネーション」</span>

- 仮の **users** テーブルの **id** は `INTEGER` 型の主キーである。**id** の昇順でカーソルページネーションを行なっており、前のページで最後に表示した **id** は100だった。次のページの最大50件を取得するため、`SELECT * FROM users` に続ける `WHERE` 句・`ORDER BY` 句・`LIMIT` 句を記述せよ。
  - **答え**: <span class="masked">`WHERE id > 100 ORDER BY id ASC LIMIT 50;`</span>

- 仮の **users** テーブルの **id** は `INTEGER` 型の主キーである。**id** の降順でカーソルページネーションを行なっており、前のページで最後に表示した **id** は100だった。次のページの最大50件を取得するため、`SELECT * FROM users` に続ける `WHERE` 句・`ORDER BY` 句・`LIMIT` 句を記述せよ。
  - **答え**: <span class="masked">`WHERE id < 100 ORDER BY id DESC LIMIT 50;`</span>

- 「カーソルページネーションを採用すれば、検索条件やインデックスに関係なく、常に高速に取得できる」という説明は正しいか。理由とともに答えよ。
  - **答え**: <span class="masked">正しくない。大きなOFFSETによる処理負担を抑えられるかどうかは、整列順と検索条件に合ったインデックスを利用できるかなどに左右される。</span>

## WHERE 句

`SELECT` 文では、`WHERE` 句を使うことで <span class="masked">指定した条件に一致するレコードだけ</span> を取り出すことが可能となります。`WHERE` 句には、`TRUE` / `FALSE` / `UNKNOWN` のいずれかに評価される「式」を与えます。そして、`WHERE` 句の評価結果が <span class="masked">TRUE</span> となったレコードだけが抽出されます。

例えば、**レベルが20以上** かつ **ギルドに所属している** (＝**guild** カラムが `NULL` ではない) という条件に一致するレコードを取得する SQL は、次のように記述することができます (**第11行目** ～ **第13行目**)。

```sql{.numberLines caption="WHEREの活用"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  level,
  guild
FROM
  characters
WHERE -- ◀ ここに注目
  level >= 20 AND
  guild IS NOT NULL
ORDER BY
  level DESC;
```

なお、`SELECT` 文は、`SELECT` 句 👉 `FROM` 句 👉 `WHERE` 句 👉 `ORDER BY` 句 👉 (`LIMIT` 句 / `OFFSET` 句) という順で記述しないと構文エラーになるので注意してください。

### 基本的な WHERE 句

**id** ( `INTEGER` 型) が「**3**」に一致するレコードを取得する `SELECT` 文は次のようになります。SQL において等価比較演算子には `==` ではなく `=` を使用するので注意してください。

```sql{.numberLines caption="WHERE句の基本(数値型の扱い)"}
SET
  search_path TO w03;

SELECT * FROM characters WHERE id = 3;
```

- `id == 3` のように `==` を使用した場合、どのようになるか予測し、実際に結果を確認してください。
- `id = '3'` のようにシングルクォートで囲んだ場合、どのようになるか予測し、実際に結果を確認してください。

---

**name** (`VARCHAR`型) が「**Alice**」に一致するレコードを取得する `SELECT` 文は次のようになります。文字列は **シングルクォート** `'` で囲むことに注意してください。

```sql{.numberLines caption="WHERE句の基本(文字列型の扱い)"}
SET
  search_path TO w03;

SELECT * FROM characters WHERE name = 'Alice';
```

- `name = Alice` のようにシングルクォートで囲まなかった場合、どのようになるか予測し、実際に結果を確認してください。


---

**created_on** ( `DATE` 型) が「**2022-03-22**」に一致するレコードを取得する `SELECT` 文は次のようになります。日付は **シングルクォート** `'` で囲み、`YYYY-MM-DD` の形式で記述してください。

```sql{.numberLines caption="WHERE句の基本(日付型の扱い)"}
SET
  search_path TO w03;

SELECT * FROM characters WHERE created_on = '2022-03-22';
```

- `created_on = '2022-3-22'` のようにゼロ埋めなしの場合、どのようになるか予測し、実際に結果を確認してください。
- `created_on = '2022/03/22'` のように `/` 区切りの場合、どのようになるか予測し、実際に結果を確認してください。
- `created_on = '2022-03-22 12:30:00'` のように時刻を含めたとき、どのようになるか予測し、実際に結果を確認してください。

---

**last_login_at** ( `TIMESTAMP` 型) が「**2025-10-03 11:42:00**」に一致するレコードを取得する `WHERE` 句は次のようになります。日時は **シングルクォート** `'` で囲み、`YYYY-MM-DD HH24:MI:SS` の形式で記述してください。

```sql{.numberLines caption="WHERE句の基本(日時型の扱い)"}
SET
  search_path TO w03;

SELECT * FROM characters WHERE last_login_at = '2025-10-03 11:42:00';
```

- `last_login_at = '2025-10-03'` のように時刻を含めない場合、どのようになるか予測し、実際に結果を確認してください。
- `last_login_at = '2025-10-03 11:42'` のように **00秒** の部分を省略した場合、どのようになるか予測し、実際に結果を確認してください。

::: {.balloon .char-01 .face-01 .tone-pink}

この演習の **last_login_at** は `TIMESTAMP` 型です。`last_login_at <= '2025-07-31'` と記述すると、右辺は `2025-07-31 00:00:00` として解釈されます。そのため、含まれるのは **2025年07月31日の00時00分00秒ちょうどまで**であり、同日の昼や夜のレコードは含まれないので注意してください。

7月31日の終わりまで含めたい場合は、**翌日の00時00分00秒より前**という条件にして、`last_login_at < '2025-08-01'` のように記述します。

- `<= '2025-07-31 23:59:59'` では、秒の小数部を持つ `23:59:59.5` などを取りこぼすため、翌日を境界にする方法が確実です。
- 7月31日の1日分だけを取得する場合は、`last_login_at >= '2025-07-31' AND last_login_at < '2025-08-01'` と記述します。

:::

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQLに関する質問です。いま `characters` テーブルの `id` カラムは `INTEGER` 型で定義されています。このとき、`id` が「3」に一致するレコードを抽出したいです。これは `SELECT * FROM characters WHERE id = 3` というSQLで実行可能なことを確認しました。  
>  
> しかし、これを `id = '3'` のように「文字列リテラル」で指定しても (予想に反して) 実行可能でした。これは、なぜですか。他の RDBMS でも同様なことが起きますか？ `id = 3` と `id = '3'` のどちらが適切ですか？

> PostgreSQLに関する質問です。いま `characters` テーブルの `created_on` カラムは `DATE` 型で定義されています。このとき、`created_on` が「2022年3月22日」に一致するレコードを抽出したいです。これは `SELECT * FROM characters WHERE created_on = '2022-03-22'` というSQLで実行可能なことを確認しました。  
>  
> しかし、これを `created_on = '2022/3/22'` のような書式で指定しても (予想に反して) 実行可能でした。これは、なぜですか。他の RDBMS でも同様なことが起きますか？ `2022-03-22` と `2022/3/22` のどちらが適切ですか？

#### 定着確認

- **users** テーブルから、**id** カラム（`INTEGER` 型で定義）が「7」に一致するレコードについて、すべてのカラムを取得するような `SELECT` 文を記述せよ。なお、比較の際は、カラムのデータ型に適したリテラルを使用すること。
  - **答え**: <span class="masked">`SELECT * FROM users WHERE id = 7;`。`id = '7'` は不正解。</span>
- **users** テーブルから、**name** カラム（`VARCHAR` 型で定義）が「Bob」に一致するレコードについて、すべてのカラムを取得するような `SELECT` 文を記述せよ。なお、比較の際は、カラムのデータ型に適したリテラルを使用すること。
  - **答え**: <span class="masked">`SELECT * FROM users WHERE name = 'Bob';`</span>
- **users** テーブルから、**created_on** カラム（`DATE` 型で定義）が「令和7年5月1日」に一致するレコードについて、すべてのカラムを取得するような `SELECT` 文を記述せよ。なお、比較の際は、カラムのデータ型に適したリテラルを使用すること。なお、令和元年は、西暦2019年である。
  - **答え**: <span class="masked">`SELECT * FROM users WHERE created_on = '2025-05-01';`</span>

- PostgreSQL の `SELECT` 文で、`WHERE` 句の条件式の評価結果が `TRUE`・`FALSE`・`UNKNOWN` となるレコードが存在する。結果セットに含まれるのは、どの評価結果のレコードか答えよ。
  - **答え**: <span class="masked">`TRUE` となるレコードだけ。`FALSE` と `UNKNOWN` となるレコードは含まれない。</span>

- **w03.characters** テーブルの **level** は `INTEGER` 型、**guild** は `VARCHAR` 型である。レベルが20以上、かつギルドに所属している（**guild** が `NULL` ではない）レコードを取得するための `WHERE` 句を記述せよ。
  - **答え**: <span class="masked">`WHERE level >= 20 AND guild IS NOT NULL`</span>

- **characters** テーブルの **last_login_at** は `TIMESTAMP` 型である。`WHERE last_login_at <= '2025-07-31'` と指定したとき、最終ログイン日時が「2025-07-31 00:00:00」のレコードと「2025-07-31 12:00:00」のレコードは、それぞれ条件に一致するか答えよ。
  - **答え**: <span class="masked">00:00:00のレコードは一致するが、12:00:00のレコードは一致しない。比較の右辺は2025-07-31 00:00:00として解釈されるため。</span>

- **characters** テーブルの **last_login_at** は `TIMESTAMP` 型で、秒の小数部も保持できる。最終ログイン日時が2025年07月31日の1日分（00時00分00秒から翌日の00時00分00秒の直前まで）に該当するレコードを取得する `WHERE` 句を記述せよ。
  - **答え**: <span class="masked">`WHERE last_login_at >= '2025-07-31' AND last_login_at < '2025-08-01'`</span>


### SQLの3値論理

SQL では `TRUE` と `FALSE` に加えて、「**不明**・**未知**」を表す `UNKNOWN` を扱う **3値論理** (**Three-Valued Logic**、**3VL**) が採用されています。`UNKNOWN` は、比較や論理演算などで **真偽を判定できない状態** を表します。PostgreSQL では、真偽値の不明は `BOOLEAN` 型の `NULL` で表されます。


たとえば <span class="masked">`level = NULL`</span> や <span class="masked">`last_login_at = NULL`</span> などの比較式を評価すると、結果は `UNKNOWN` となります。一方、`level + NULL` の計算結果は `INTEGER` 型の `NULL` であり、真偽値の `UNKNOWN` とは区別します。

- `IS NULL` や `IS NOT NULL` は**特別に真偽を判定できる例外的な存在**です。

この `UNKNOWN` が混ざると、**論理演算** (`AND`・`OR`・`NOT`) の結果も `UNKNOWN` を含む形で評価されることに十分に注意してください。

#### SQLの3値論理の論理否定 (NOT)

3値論理の「**論理否定**」は次のようになります。

| A         | NOT A     |
|:----------:|:----------:|
| TRUE       | FALSE      |
| FALSE      | TRUE       |
| <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> |

実際に、この関係を確認するためには、次のような SQL を実行します。

- 以下の SQL では、不明な真偽値を表すために `NULL` を記述します。
- 本演習の `npm run sql` が内部で使用する **psql** の既定の出力では、`TRUE` は「**t**」、`FALSE` は「**f**」、`NULL` は「**空欄**」として表示されます。
- SQLでは真偽値も <span class="masked">大文字と小文字を区別しません</span>。そのため `TRUE` も `True` も `true` も同じです。以下の SQL では、見やすさを重視して `True`、`False`、`Null` の表記を使用しています。

```sql{.numberLines caption="UNKNOWNを含む論理否定"}
SELECT
  NOT True AS "NOT True",
  NOT False AS "NOT False",
  NOT Null AS "NOT Unknown"; 
```

- 実際に、実行して結果を確かめてみてください。

#### SQLの3値論理の論理積 (AND)

3値論理の「**論理積 (AND)**」は次のようになります。

| A         | B         | A AND B  |
|:----------:|:----------:|:---------:|
| TRUE       | TRUE       | TRUE      |
| TRUE       | FALSE      | FALSE     |
| TRUE       | <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> |
| FALSE      | TRUE       | FALSE     |
| FALSE      | FALSE      | FALSE     |
| FALSE      | <font color="deeppink">UNKNOWN</font> | FALSE     |
| <font color="deeppink">UNKNOWN</font> | TRUE       | <font color="deeppink">UNKNOWN</font> |
| <font color="deeppink">UNKNOWN</font> | FALSE      | FALSE     |
| <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> |

`UNKNOWN` を含まないときは、従来の2値論理 (`TRUE`/`FALSE`) の **論理積** (**AND**) と同じ結果となります。一方、`UNKNOWN` が含まれる場合は、次のように考えます。

- `TRUE AND UNKNOWN` の演算結果は、以下のように**どちらの結果にもなり得るため**、`UNKNOWN` と考えます。
  - 仮に `UNKNOWN` が `TRUE` であれば `TRUE AND (TRUE) 👉 TRUE`
  - 仮に `UNKNOWN` が `FALSE` であれば `TRUE AND (FALSE) 👉 FALSE`
- `FALSE AND UNKNOWN` の演算結果は、以下のように常に `FALSE` になるため、`FALSE` と考えます。
  - 仮に `UNKNOWN` が `TRUE` であれば `FALSE AND (TRUE) 👉 FALSE`
  - 仮に `UNKNOWN` が `FALSE` であれば `FALSE AND (FALSE) 👉 FALSE`

次の SQL を実行して実際に確認してみてください。

```sql{.numberLines caption="UNKNOWNを含む論理積 (AND)"}
SELECT
  True AND Null AS "True AND Unknown",
  False AND Null AS "False AND Unknown",
  Null AND Null AS "Unknown AND Unknown"; 
```

#### SQLの3値論理の論理和 (OR)

3値論理の「**論理和 (OR)**」は次のようになります。

| A         | B         | A OR B   |
|:----------:|:----------:|:---------:|
| TRUE       | TRUE       | TRUE      |
| TRUE       | FALSE      | TRUE      |
| TRUE       | <font color="deeppink">UNKNOWN</font> | TRUE      |
| FALSE      | TRUE       | TRUE      |
| FALSE      | FALSE      | FALSE     |
| FALSE      | <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> |
| <font color="deeppink">UNKNOWN</font> | TRUE       | TRUE      |
| <font color="deeppink">UNKNOWN</font> | FALSE      | <font color="deeppink">UNKNOWN</font> |
| <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> | <font color="deeppink">UNKNOWN</font> |

`UNKNOWN` を含まないときは、従来の2値論理 (`TRUE`/`FALSE`) の **論理和** (**OR**) と同じ結果となります。一方、`UNKNOWN` が含まれる場合は、次のように考えます。

- `TRUE OR UNKNOWN` の演算結果は、以下のように常に `TRUE` になるため、`TRUE` と考えます。
  - 仮に `UNKNOWN` が `TRUE` であれば `TRUE OR (TRUE) 👉 TRUE`
  - 仮に `UNKNOWN` が `FALSE` であれば `TRUE OR (FALSE) 👉 TRUE`
- `FALSE OR UNKNOWN` の演算結果は、以下のように**どちらの結果にもなり得るため**、`UNKNOWN` と考えます。
  - 仮に `UNKNOWN` が `TRUE` であれば `FALSE OR (TRUE) 👉 TRUE`
  - 仮に `UNKNOWN` が `FALSE` であれば `FALSE OR (FALSE) 👉 FALSE`

次の SQL を実行して実際に確認してみてください。

```sql{.numberLines caption="UNKNOWNを含む論理和 (OR)"}
SELECT
  True OR Null AS "True OR Unknown",
  False OR Null AS "False OR Unknown",
  Null OR Null AS "Unknown OR Unknown"; 
```

### WHERE句でよく利用する述語

SQLにおいて、`TRUE`・`FALSE`・`UNKNOWN` のいずれかに評価される条件式を **述語** (**Predicate**) といいます。代表的なものとして...

- 比較述語 (**比較演算子**)
- NULL判定述語
- IN述語 (**IN演算子**)
- LIKE述語 (**LIKE条件**、**パターンマッチ演算子**)
- BETWEEN述語 (**BETWEEN条件**、**範囲演算子**) 

...があります。実務では、括弧内の表記で呼ばれることが多いです。

---

- **比較演算子**: `=`（等しい）、`<`（より小さい）、`<=`（以下）、`>`（より大きい）、`>=`（以上）、`<>`（等しくない）など。
  - PostgreSQL のほか、様々な RDBMS で `<>` の代わりに `!=` を不等価演算子として使用することができます。ただし、標準 SQL で定められているのは `<>` のほうなので、原則として <span class="masked">`<>`</span> を使用してください。
- **NULL判定述語**: `IS NULL`、`IS NOT NULL` など。
  - NULL判定には <span class="masked">`= NULL`</span> ではなく、必ず `IS NULL` を使用してください。`= NULL` の評価結果は、常に `UNKNOWN` となります。
  - PostgreSQL では、`ISNULL` と `NOTNULL` を使用することもできます。


#### IN述語 (IN演算子)

ジョブが「Priest」または「Wizard」のレコードを抽出する SQL は、**IN演算子** を使用して次のように記述することができます。条件としては `job = 'Priest' OR job = 'Wizard'` と同じですが <span class="masked">より簡潔に記述できるメリット</span> があります。

```sql{.numberLines caption="IN演算子"}
SET
  search_path TO w03;

SELECT
  *
FROM
  characters
WHERE
  job IN ('Priest', 'Wizard');
```

なお、文字列の比較は、大文字と小文字を**区別する**ので注意してください。`job IN ('priest', 'wizard')` のようにすると、<span class="masked">抽出されるレコードは「0件」</span> になります。

また、`IN` は、論理否定の `NOT` と組み合わせることができます。たとえば、Priest と Wizard 以外のジョブ (つまり、Fighter、Monk、Ninja、Samurai) を抽出する SQL は次のように記述できます。

```sql{.numberLines caption="IN演算子(NOTと組み合わせ)"}
SET
  search_path TO w03;

SELECT
  *
FROM
  characters
WHERE
  job NOT IN ('Priest', 'Wizard');
```

ここでは `NOT job IN ('Priest', 'Wizard')` のように記述しても、条件の意味と結果は同じです。ただし、本科目では、否定の対象が読み取りやすい `job NOT IN ('Priest', 'Wizard')` の記法を使用してください。

なお、`WHERE` 句で `NOT IN` を使用するとき、リストに <span class="masked">`NULL`</span> を含むと、評価結果は `FALSE` または `UNKNOWN` となり、1件のレコードも抽出されなくなるので注意してください。例えば、ギルドが、Yamato、無所属 (`NULL`) **以外** のレコードを抽出したいとき、次の SQL では意図した結果が得られません。実際に確認してみてください。

```sql{.numberLines caption="意図した結果が得られないSQL"}
SET
  search_path TO w03;

SELECT
  *
FROM
  characters
WHERE
  guild NOT IN ('Yamato', NULL); -- Yamato と NULL 以外を抽出したい
```

この例では、**guild** が `Yamato` のレコードは `FALSE`、それ以外のギルドや `NULL` のレコードは `UNKNOWN` となります。`TRUE` となるレコードがないため、結果は0件になります。意図した条件は、`WHERE guild <> 'Yamato' AND guild IS NOT NULL` と記述できます。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL で、`NOT job IN ('Priest', 'Wizard')` と `job NOT IN ('Priest', 'Wizard')` は同じ結果になると学びました。それぞれの条件の意味と、後者のほうが否定の対象を読み取りやすい理由を説明してください。

> SQLに関する質問です。あるテーブルにギルドというカラムがあります。いま、ギルドのカラム値が `Yamato` または `NULL` 以外のレコードを抽出したいです。そのために `guild NOT IN ('Yamato', NULL)` のように、WHERE句を書いたのですが、意図した結果がえられません。なぜ、このようなことが起きますか。

#### LIKE述語 (LIKE条件、パターンマッチ演算子)

キャラクタの名前が「**C**」から始まるようなレコードを抽出したいときは、`LIKE` 条件を使用し、次のように SQL を記述します。

```sql{.numberLines caption="LIKE条件"}
SET
  search_path TO w03;

SELECT
  *
FROM
  characters
WHERE
  name LIKE 'C%';
```

ここで `%` (＝**ワイルドカード**) は <span class="masked">0文字以上の任意の文字列</span> を表し、`C%` は、大文字の「C」から始まる任意の文字列 (**「C」だけの1文字の文字列を含む**) を表現しています。そのため、`WHERE name LIKE 'C%'` では、**name** カラムが「**C**harlie」「**C**arol」「**C**haplin」のようなレコードだけが抽出されます。

なお、大文字と小文字を区別するので、**name** が「chris」のレコードは抽出されません。小文字を含めて抽出したいときは <span class="masked">`UPPER(name) LIKE 'C%'`</span> のようにします。

- 特定の文字で終わるレコードを抽出したいとき (後方一致検索) は、**ワイルドカード** `%` を前に置きます。例えば「セルゲエ**ビッチ**」「ミハイロ**ビッチ**」「ペトロ**ビッチ**」のように「ビッチ (**vich**) 」で終わる名前のレコードを抽出したいときは <span class="masked">`name LIKE '%vich'`</span> のようにします。
- 特定の文字を含むレコードを抽出したいとき (中間一致検索) は、**ワイルドカード** `%` を検索文字列の前後に配置します。たとえば、**dra** を含む名前を抽出したいときは `LOWER(name) LIKE '%dra%'` のようにします。
  - **Dra**cula (**ドラ**キュラ)、Cen**dra**l (セン**ドラ**ル)、Hy**dra** (ハイ**ドラ**) などがマッチします。

#### BETWEEN述語 (BETWEEN条件、範囲演算子)

「**XX 以上 YY 以下**」のような**範囲条件**でレコードを抽出したいときは、`BETWEEN` を使うことで簡潔に `WHERE` 句を記述することができます。

例えば、**level** が **20以上39以下** のレコードを抽出したい場合、次のように SQL を記述することができます。

```sql{.numberLines caption="BETWEENを使用した範囲条件の指定"}
SET
  search_path TO w03;

SELECT
  *
FROM
  characters
WHERE
  level BETWEEN 20 AND 39;
```

この条件は `WHERE level >= 20 AND level <= 39` と同じ意味になりますが、`BETWEEN` を使うほうが可読性に優れています。なお、`BETWEEN` は <span class="masked">両端の値を含むこと</span> に注意してください。上記の例では、レベルが `39` のレコードも **含まれます**。

- Python の `range(20,39)` のように上限を除外する仕様とは**異なる**ため、混同しないように注意してください。

`BETWEEN` は、特に `DATE` 型や `TIMESTAMP` 型のカラムでよく使用されます。例えば、最終ログイン日時 (`TIMESTAMP`型) が「2025-07-01」から「2025-07-31」までの範囲にあるレコードを抽出したいときは次のように記述します。

```sql{.numberLines caption="BETWEENによる日付範囲の抽出"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  last_login_at
FROM
  characters
WHERE
  last_login_at BETWEEN '2025-07-01 00:00:00' AND '2025-07-31 23:59:59.999999'
ORDER BY
  last_login_at;
```

- **注意**: `WHERE last_login_at BETWEEN '2025-07-01' AND '2025-07-31'` とすると、**last_login_at** が <span class="masked">2025年7月31日 10時15分</span> のようなレコードが選択されないので注意してください。
    - なお、**last_login_at** が、**created_on** のように時刻を含まない `DATE` 型であれば、この問題は生じません。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> PostgreSQL に関する質問です。last_login_at という `TIMESTAMP` 型のカラムがあります。このとき、`WHERE last_login_at BETWEEN '2025-07-01' AND '2025-07-31'` では、`2025-07-31 10:15:00` のようなレコードが選択されないのはなぜですか。

---

さらに、[前回講義](lecture03.html#日付時刻関数を利用する) で紹介した `DATE_PART` 関数と組み合わせることで、最終ログインが「**9時台から17時台**」のレコードを抽出するようなこともできます。

```sql{.numberLines caption="9時台〜17時台にログインしているレコードを取得"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  last_login_at
FROM
  characters
WHERE
  DATE_PART('hour', last_login_at) BETWEEN 9 AND 17
ORDER BY
  CAST(last_login_at AS TIME); -- 時刻で整列
```

- `DATE_PART('hour', last_login_at)` は、時の部分を0〜23の数値として返します。戻り値の型は `INTEGER` ではなく `DOUBLE PRECISION` です。`BETWEEN 9 AND 17` は「**9時台〜17時台の間**」を意味します (**17時台の終わりまでを含む**ことに注意してください)。

#### 定着確認

- **w03.characters** テーブルの **job** は `VARCHAR` 型である。ジョブが `Priest` または `Wizard` のレコードを取得するための `WHERE` 句を、`IN` を使用して記述せよ。
  - **答え**: <span class="masked">`WHERE job IN ('Priest', 'Wizard')`</span>

- **w03.characters** テーブルの **guild** は `VARCHAR` 型で、未所属の場合は `NULL` となる。Yamatoにも所属せず、未所属でもないレコードを取得するために `WHERE guild NOT IN ('Yamato', NULL)` と記述した。この条件が意図どおりにならない理由を説明し、正しい `WHERE` 句を記述せよ。
  - **答え**: <span class="masked">YamatoのレコードではFALSE、それ以外のギルドやNULLのレコードではUNKNOWNとなり、TRUEになるレコードがないため。正しい条件は `WHERE guild <> 'Yamato' AND guild IS NOT NULL`。</span>

- **w03.characters** テーブルの **name** は `VARCHAR` 型である。英字の大文字と小文字を区別せず、名前が「C」または「c」から始まるレコードを取得する `WHERE` 句を、`UPPER` と `LIKE` を使用して記述せよ。
  - **答え**: <span class="masked">`WHERE UPPER(name) LIKE 'C%'`。`%` は0文字以上の任意の文字列を表すため、「C」や「c」だけの名前も条件に一致する。</span>

- あるテーブルの **level** は `INTEGER` 型で、19・20・39・40・`NULL` の値を持つレコードが存在する。`WHERE level BETWEEN 20 AND 39` と指定したとき、どの値を持つレコードが結果セットに含まれるか答えよ。
  - **答え**: <span class="masked">20と39。BETWEENは両端を含む。19と40は範囲外であり、NULLの場合はUNKNOWNとなるため含まれない。</span>

- **characters** テーブルの **last_login_at** は `TIMESTAMP` 型である。2025年07月01日から07月31日の終わりまでのレコードを取得するために `WHERE last_login_at BETWEEN '2025-07-01' AND '2025-07-31'` と記述した。この条件では7月31日の日中が含まれない理由を説明し、秒の小数部も取りこぼさない `WHERE` 句に書き換えよ。
  - **答え**: <span class="masked">上限が2025-07-31 00:00:00として解釈されるため。`WHERE last_login_at >= '2025-07-01' AND last_login_at < '2025-08-01'` とする。</span>

- **characters** テーブルの **last_login_at** は `TIMESTAMP` 型である。`WHERE DATE_PART('hour', last_login_at) BETWEEN 9 AND 17` と指定したとき、最終ログイン日時が「2025-07-31 17:59:59.5」のレコードと「2025-07-31 18:00:00」のレコードは、それぞれ条件に一致するか。また、`DATE_PART` の戻り値の型も答えよ。
  - **答え**: <span class="masked">17:59:59.5は時の部分が17なので一致し、18:00:00は18なので一致しない。戻り値の型はDOUBLE PRECISION。</span>

### CASE式を使用したWHERE句の指定

`CASE` 式は、`WHERE` 句でも利用することができます (先にも述べましたが、式を記述できる場所であれば、どこでも `CASE` 式を利用することができます)。

たとえば、**ギルドに所属している場合はレベル 60 以上**、**未所属の場合はレベル 30 以上** のレコードを抽出したいとき、次のように SQL を記述することができます。

```sql{.numberLines caption="WHERE句におけるCASE式の利用1"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  guild,
  level
FROM
  characters
WHERE -- ◀ ここに注目
  level >= CASE
    WHEN guild IS NOT NULL THEN 60
    ELSE 30
  END
ORDER BY
  level DESC;
```

この例では、`CASE` 式がギルドへの所属状況に応じて「60」または「30」を返します。その値を比較の基準として、`level >= 60` または `level >= 30` の条件でレコードを抽出しています。

これは、次のように記述することもできます。

```sql{.numberLines caption="WHERE句におけるCASE式の利用2"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  guild,
  level
FROM
  characters
WHERE
  CASE
    WHEN guild IS NOT NULL AND level >= 60 THEN TRUE
    WHEN guild IS NULL AND level >= 30 THEN TRUE
    ELSE FALSE
  END
ORDER BY
  level DESC;
```

この例では、`CASE` 式そのものが `TRUE` または `FALSE` を返します。その真偽値を `WHERE` 句の条件として使用し、`TRUE` となるレコードだけを抽出しています。

また、`CASE` 式を使用せずに、次のように記述することもできます。

```sql{.numberLines caption="CASE式を使用しない例"}
SET
  search_path TO w03;

SELECT
  id,
  name,
  guild,
  level
FROM
  characters
WHERE
  (guild IS NOT NULL AND level >= 60 ) OR
  (guild IS NULL AND level >= 30 )
ORDER BY
  level DESC;
```

3通りの SQL は、いずれも次の8件を取得します。

```
 id |  name   | guild  | level
----+---------+--------+-------
  9 | Walter  |        |    73
 16 | Steve   | hameln |    70
 12 | Dave    | Yamato |    68
 13 | Mallet  | D.D.D  |    64
  2 | Zach    | D.D.D  |    62
 19 | Jack    | hameln |    61
  3 | Charlie |        |    57
  5 | Ivan    |        |    39
```

#### SQLドリル💻

- `ex-05_1.sql` 👉 **w03.characters** テーブルから、**buff** が `0.00` 以外のレコードを抽出して、第1キーを **buff** (降順)、第2キーを **level** (降順) でソートするような SQL を記述せよ。なお、id、name、level、buff のカラムを出力すること。

```
 id |  name  | level | buff  
----+--------+-------+-------
 13 | Mallet |    64 |  0.10
  2 | Zach   |    62 |  0.10
 17 | Wendy  |    56 |  0.10
 11 | Ellen  |    51 |  0.10
 14 | Eve    |    46 |  0.10
 16 | Steve  |    70 |  0.05
 19 | Jack   |    61 |  0.05
 10 | Oscar  |    44 |  0.05
  8 | Bob    |    33 |  0.05
  5 | Ivan   |    39 | -0.07
  1 | Marvin |    35 | -0.15
 18 | Carol  |    28 | -0.20
```

- `ex-05_2.sql` 👉 **w03.characters** テーブルから、**name** が「T」からはじまるレコードについて、以下のようなカラムを **name** の昇順で取得する SQL を記述せよ。

```
 id | name  | level | created_on 
----+-------+-------+------------
  4 | Tom   |     1 | 2020-12-05
 15 | Trent |    50 | 2023-10-04
  7 | Trudy |    48 | 2021-11-28
```

- `ex-05_3.sql` 👉 **w03.characters** テーブルから、**created_on** が「2021年」と「2022年」のレコードについて、以下のようなカラムを **created_on** の昇順で取得する SQL を記述せよ。ここでは、BETWEEN述語を使用することを期待している。

```
 id |  name  | level | created_on 
----+--------+-------+------------
  5 | Ivan   |    39 | 2021-02-15
  6 | Alice  |    42 | 2021-06-14
  7 | Trudy  |    48 | 2021-11-28
  8 | Bob    |    33 | 2022-03-22
  9 | Walter |    73 | 2022-04-06
 11 | Ellen  |    51 | 2022-08-30
 10 | Oscar  |    44 | 2022-11-10
```

- `ex-05_4.sql` 👉 **w03.characters** テーブルから、**created_on** が「2021年」と「2022年」**以外**のレコードについて、以下のようなカラムを取得する SQL を記述せよ。整列の基準は、第1キーを **created_on** (昇順)、第2キーを **id** (昇順) とすること。ここでは、BETWEEN述語を使用することを期待している。
  - **ヒント**: <span class="masked">`NOT`を利用する</span>

```
 id |  name   | level | created_on 
----+---------+-------+------------
  1 | Marvin  |    35 | 2020-09-23
  2 | Zach    |    62 | 2020-10-25
  3 | Charlie |    57 | 2020-12-05
  4 | Tom     |     1 | 2020-12-05
 12 | Dave    |    68 | 2023-01-19
 13 | Mallet  |    64 | 2023-02-02
 14 | Eve     |    46 | 2023-09-07
 15 | Trent   |    50 | 2023-10-04
 16 | Steve   |    70 | 2024-01-27
 17 | Wendy   |    56 | 2024-03-18
 18 | Carol   |    28 | 2024-05-11
 19 | Jack    |    61 | 2024-07-12
```

#### 定着確認

- **characters** テーブルの **guild** は `VARCHAR` 型、**level** は `INTEGER` 型である。`WHERE level >= CASE WHEN guild IS NOT NULL THEN 60 ELSE 30 END` と指定したとき、「guildがYamato かつ levelが59」のレコードと「guildがNULL かつ levelが30」のレコードは、それぞれ抽出されるか。`CASE` 式が返す基準値とともに答えよ。
  - **答え**: <span class="masked">Yamato・レベル59ではCASEが60を返し、59 >= 60はFALSEなので抽出されない。NULL・レベル30ではCASEが30を返し、30 >= 30はTRUEなので抽出される。</span>

- **characters** テーブルの **guild** は `VARCHAR` 型、**level** は `INTEGER` 型である。`WHERE CASE WHEN guild IS NOT NULL AND level >= 60 THEN TRUE WHEN guild IS NULL AND level >= 30 THEN TRUE ELSE FALSE END` の `CASE` 式が返す値の型と、どの値を返したレコードが抽出されるかを答えよ。
  - **答え**: <span class="masked">BOOLEAN型。CASE式がTRUEを返したレコードだけが抽出され、FALSEを返したレコードは抽出されない。</span>

- **characters** テーブルの **guild** は `VARCHAR` 型、**level** は `INTEGER` 型である。**guild** が `NULL` ではない場合はレベル60以上、`NULL` の場合はレベル30以上のレコードを取得したい。`CASE` 式が比較の基準値を返す形で、`WHERE` 句を記述せよ。
  - **答え**: <span class="masked">`WHERE level >= CASE WHEN guild IS NOT NULL THEN 60 ELSE 30 END`</span>

- **characters** テーブルの **guild** は `VARCHAR` 型、**level** は `INTEGER` 型である。`WHERE level >= CASE WHEN guild IS NOT NULL THEN 60 ELSE 30 END` と同じレコードを取得する条件を、`CASE` 式を使用せず、`AND`・`OR`・括弧を使用して記述せよ。`WHERE` キーワードも含めること。
  - **答え**: <span class="masked">`WHERE (guild IS NOT NULL AND level >= 60) OR (guild IS NULL AND level >= 30)`</span>

- **characters** テーブルの **guild** は `VARCHAR` 型である。`WHERE CASE WHEN guild IS NOT NULL THEN 60 ELSE 30 END` という条件は、PostgreSQL で実行できるか。`CASE` 式が返す値の型と、`WHERE` 句に必要な値の型に着目して理由を答えよ。
  - **答え**: <span class="masked">実行できない。CASE式が返す値はINTEGER型だが、WHERE句の条件にはBOOLEAN型の値が必要である。数値の60や30を、そのまま真偽値として使用することはできない。</span>

- **characters** テーブルの **guild** は `VARCHAR` 型、**level** は `INTEGER` 型である。`WHERE level >= CASE WHEN guild IS NOT NULL THEN 60 END` と指定したとき、**guild** が `NULL`、**level** が40のレコードは抽出されるか。`ELSE` を省略した `CASE` 式の結果と、比較結果を含めて答えよ。
  - **答え**: <span class="masked">抽出されない。WHENの条件に一致せず、ELSEもないためCASE式はNULLを返す。40 >= NULLの結果はUNKNOWNとなり、WHERE句では抽出されない。</span>

- 次の真理値表の空欄を埋めよ。ただし、SQL の 3 値論理に従い、`TRUE`、`FALSE`、`UNKNOWN` のいずれかを答えること。
  - **答え**:【1-1】<span class="masked">UNKNOWN</span>
  - **答え**:【1-2】<span class="masked">TRUE</span>
  - **答え**:【2-1】<span class="masked">FALSE</span>
  - **答え**:【2-2】<span class="masked">UNKNOWN</span>

| A         | B         | A AND B  | A OR B  |
|:----------:|:----------:|:---------:|:---------:|
| UNKNOWN    | TRUE       | 【1-1】     |【1-2】      |
| UNKNOWN    | FALSE      | 【2-1】     |【2-2】      |

- `SELECT` 文において、**guild**カラムが `NULL` ではないレコードのみを取得したい。どのように `WHERE` 句を記述すればよいか。`WHERE` キーワードを含めて答えよ。
  - **答え**: <span class="masked">`WHERE guild IS NOT NULL`</span>
- `SELECT` 文において、**guild**カラムが `Yamato` ではないレコードを取得したい (**guild**カラムが `NULL` であるレコードも含めて取得したい)。どのように `WHERE` 句を記述すればよいか。`WHERE` キーワードを含めて答えよ。
  - **答え**: <span class="masked">`WHERE guild <> 'Yamato' OR guild IS NULL`</span>

## INSERT文 (超基礎編)

テーブルにレコードを追加するときには `INSERT` 文を使用します。例えば、**w03.users** テーブルが次のようなスキーマ (構造・データ型) のとき...

```sql{.numberLines caption="from-teacher/03/init-users.sql (抜粋)"}
CREATE TABLE users (
  id INTEGER PRIMARY KEY, -- 主キー (Primary Key) 設定
  name VARCHAR(16) NOT NULL, -- NULL を不許可
  age INTEGER -- NULL も許可
);
```

このテーブルに **Carol (18歳)** を追加する場合は、次のような `INSERT` 文を記述します。

**次の SQL は説明用なので、単独では実行しないでください**。実行するときは、後述の `START TRANSACTION` ～ `ROLLBACK` を含む SQL 全体を使用してください。

```sql{.numberLines caption="usersにレコードを追加するINSERT文"}
SET
  search_path TO w03;

INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18);
```

ここで、**第07行目** の `3` は **id** を表し、既に「Alice」と「Bob」の2名が登録されているため、次の連番として `3` を設定しています。

- **id** は `CREATE TABLE` 文において `id INTEGER PRIMARY KEY` のように **主キー設定** (Primary Key、プライマリキー) しているカラムなので、既に他のレコードで使用している `1` や `2` を設定することはできません。

ここで、実際にレコードの挿入を試してみたいのですが、上記の SQL (`INSERT` 文) をそのまま実行すると、<span class="masked">ここまでに書いてきた `SELECT` 文を再実行したときの結果が変わってしまうおそれ</span> があります。そこで、ここでは **トランザクション** と **ロールバック** という RDBMS の仕組みを利用して、データを保護しながら `INSERT` 文の動きを確かめていきます。

**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> リレーショナルデータベースにおける主キー (Primary Key) とは何ですか。主キーには同じ値を設定できないと聞いたのですが、なぜですか。

### トランザクションとロールバックの利用

`INSERT` 文の動作を実際に試しながらも、追加したレコードを残さないようにするため、ここでは**明示的にトランザクションを開始**し、レコードの挿入と、その確認を行った後に、<span class="masked">ロールバックによって挿入を取り消す</span> という手順をとります。

トランザクションの詳しい仕組みは今後の授業で扱います。ここでは、`START TRANSACTION` のあとに挿入したレコードを、最後の `ROLLBACK` で取り消します。途中の `SELECT` では追加したレコードを確認できますが、**変更はまだ確定していません**。

具体的には、次の SQL によってレコードの挿入を試しつつ、**最後にロールバックによって挿入したレコードを取り消す**ことができます。

```sql{.numberLines caption="トランザクションとロールバックによるINSERTの検証"}
SET
  search_path TO w03;

-- トランザクションを開始
START TRANSACTION;

-- レコードの挿入
INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18);

-- 結果の確認
SELECT * FROM users;

-- このトランザクションで挿入したレコードを取り消し (ロールバック)
ROLLBACK;
```

上記の SQL を実行してみてください。次のような結果が得られるはずです。

```
 id | name  | age
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
  3 | Carol |  18
```

つづいて、ロールバックによって「Carol」のレコードの挿入が取り消されていることを確認してみます。

(`START TRANSACTION` ～ `ROLLBACK` で囲まずに) `SELECT * FROM w03.users;` を実行してみてください。ロールバックにより、「Carol」のレコードの挿入は取り消され、**テーブルのレコードは元の2件に戻っているはず** です。

```
 id | name  | age 
----+-------+-----
  1 | Alice |  20
  2 | Bob   |  25
```

今後しばらくは、レコードを挿入する `INSERT` 文、レコードを削除する `DELETE` 文、レコードを更新する `UPDATE` 文などは `START TRANSACTION` ～ `ROLLBACK` の範囲内で試すようにしてください。

なお、**第17行目**の `ROLLBACK` を <span class="masked">`COMMIT`</span> に置き換えると、**変更内容が確定し、その後も追加したレコードが残ります**（今回はあくまで練習なので、最後は `ROLLBACK` にしてください）。

::: {.note .type-tips}
**`START TRANSACTION` ～ `ROLLBACK` で囲まずに実行してしまったときは...**

誤って変更を確定したテーブルに応じて、次のコマンドで初期化してください。**対象テーブルの既存データも初期状態に戻る**ため、実行するコマンドを確認してください。

**w03.users** テーブルを変更した場合:

```bash
npm run sql from-teacher/03/init-users.sql
```

**w03.characters** テーブルを変更した場合:

```bash
npm run sql from-teacher/03/init-characters.sql
```
:::


**<i class="fa-solid fa-comment-dots fa-flip-horizontal"></i>プロンプト例**

> リレーショナルデータベースにおいて、トランザクションおよびロールバックとは何ですか。先生から「繰り返し演習するために、INSERT文やDELETE文は `START TRANSACTION` ～ `ROLLBACK` で囲んで実行するように」と指示されました。これはどういう意味でしょうか。

### 複数レコードの挿入

2件以上のレコードを同時に挿入したいときは、次のように `VALUES` 句内で **カンマ区切り** でデータを記述します。実際に実行して確認してください。

```sql{.numberLines caption="2件以上のレコードを同時に挿入"}
SET
  search_path TO w03;

START TRANSACTION;

INSERT INTO
  users (id, name, age)
VALUES
  (3, 'Carol', 18),
  (4, 'Dave', NULL),
  (5, 'Ellen', 17);

SELECT * FROM users; -- 確認

ROLLBACK;
```

- **age** カラムには、`NOT NULL` 制約がないので **第10行目** のように `NULL` を設定することができます。
- **第10行目** で、`'Dave'` を `NULL` にすると、どのようになるか確認してください。
- **第11行目** を `(1, 'Ellen', 17)` のように **id** が重複するようにすると、どのようになるか確認してください。

後者の2つの変更では、制約違反によって **`INSERT` 文全体が失敗します**。エラーになったレコードより前に記述した「Carol」なども含め、この `INSERT` 文によるレコードは1件も追加されません。

### カラム指定の順序と省略

次のように `INSERT INTO` 句では、**カラムの指定順序を任意に変更すること** ができます。
また、「NULLを許容するカラム」や「デフォルト値が設定されているカラム」については、指定を省略することも可能です。

```sql{.numberLines caption="カラム指定の順序と省略"}
SET
  search_path TO w03;

START TRANSACTION;

INSERT INTO
  users (name, id) -- カラムの順序に注目
VALUES
  ('Carol', 3), -- 指定したカラム順に対応して値を記述
  ('Dave', 4),
  ('Ellen', 5);

SELECT * FROM users; -- 確認

ROLLBACK;
```

実際に実行して、省略された **age** がどのような値になっているかを確認してください。

省略したカラムには、デフォルト値が設定されていればその値が、設定されていなければ `NULL` が入ります。今回の **age** にはデフォルト値が設定されていないため、`NULL` になります。

::: {.note .type-caution}
**自動採番の番号はロールバックで戻りません**

ここまでの **w03.users** では **id** を手動で指定しましたが、このあとのドリルで使用する **w03.characters** では **id** が自動採番されます。自動採番の番号は、ロールバックしても元に戻りません。同じ演習を繰り返すと番号が飛ぶことがありますが、**挿入したレコードが残ったという意味ではありません**。
:::

#### SQLドリル💻

- `ex-06_1.sql` 👉 **w03.characters** テーブルに、以下に示すような2件のレコードを挿入する SQL を記述せよ。
  - <i class="fa-brands fa-github"></i> [from-teacher/03/init-characters.sql](https://github.com/TakeshiWada1980/DB-2026-PostgreSQL/blob/main/from-teacher/03/init-characters.sql) の `INSERT` 文を参考にすること。
  - `START TRANSACTION` ～ `ROLLBACK` で囲んで実行すること。

```
  name   |   job   | level | buff  | guild  |    last_login_at    | created_on
---------+---------+-------+-------+--------+---------------------+------------
 Zoe     | Paladin |    11 |  0.00 | W.Wind | 2025-10-20 15:48:00 | 2025-10-12
 Justin  | Archer  |     2 |  0.50 |        | 2025-10-23 11:28:00 | 2025-10-23
 ```


## 授業時間外学習の指示 (宿題)

🚨**本科目は「学修単位科目」であり、1回の講義あたり「4時間相当」の授業時間外学習が求められる科目です**🏃

- 次回の講義で「**小テスト❹**」を実施します。
  - **定着確認** および **SQLドリル** から主に出題します。
  - 講義が進行するにつれて、当然ながら小テストの内容も複雑で高度なものになっていきます。前半で、しっかりと得点をとるようにしてください。

---

- この講義資料を再読・熟読し「不明な用語」や「理解が不十分な用語」があればインターネットや、ChatGPTなどの生成AIを利用して解決してください。また、興味関心を持ったトピックについて、ウェブ、生成AI、YouTube動画などを利用して知識を広げ、理解を深めてください。
  - 特に **プロンプト例** を示しているものについては、実際に生成AIにプロンプトを投げ、さらに対話を重ねることで、知識の幅を広げるだけでなく、理解をより深く確かなものにしてください。
- 講義資料内の「**演習**」や「**SQLドリル**」に再度取り組んでください。特に、**SQLドリル**💻 は、授業時間中に1回取り組むだけでは定着しないので注意してください。
