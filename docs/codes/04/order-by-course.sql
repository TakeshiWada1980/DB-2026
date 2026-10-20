-- 以下は ORDER BY 句だけの解答例であり、この SQL は単体では実行できません。
ORDER BY
  CASE
    WHEN course = 'M' THEN 1
    WHEN course = 'D' THEN 2
    WHEN course = 'E' THEN 3
    WHEN course = 'I' THEN 4
  END ASC;
