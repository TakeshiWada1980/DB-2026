-- 定着確認: course は D、E、I、M のいずれかで、NULL は含まれない。
-- CASE 式を使用し、M、D、E、I の順に整列する ORDER BY 句を記述せよ。
-- 以下は ORDER BY 句だけの解答例であり、この SQL は単体では実行できません。
-- course カラムを持つテーブルを参照する SELECT 文の一部として使用してください。

ORDER BY
  CASE
    WHEN course = 'M' THEN 1
    WHEN course = 'D' THEN 2
    WHEN course = 'E' THEN 3
    WHEN course = 'I' THEN 4
  END ASC;
