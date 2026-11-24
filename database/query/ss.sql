USE db_fnmodel;

CREATE TABLE tb_class_config (
  class_id        CHAR(1)       NOT NULL,
  class_base      DECIMAL(10,2) NOT NULL,
  class_per_min   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tb_class_config (class_id, class_base, class_per_min) VALUES
  ('A', 50, 5),
  ('B', 30, 3),
  ('C', 10, 1)
ON DUPLICATE KEY UPDATE
  class_base    = VALUES(class_base),
  class_per_min = VALUES(class_per_min);
