-- =========================================================================
-- ЗАПРОС 1: Фильтрация по одной таблице
-- Задача: найти перевозки с весом > 1000 кг и расстоянием > 1000 км,
-- отсортированные по статусу.
-- =========================================================================

-- ШАГ 1.1: Замер без индексов
-- Удаляем индексы, если они были созданы ранее, для чистоты эксперимента.
DROP INDEX IF EXISTS idx_transport_filter_composite;
DROP INDEX IF EXISTS idx_transport_optimized;

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
SELECT transport_id, item_name, transport_date, weight, distance, comment
FROM item_transportation
WHERE transport_date >= '2023-01-01'
  AND weight > 1000
  AND distance > 1000
  AND status_id = 2
LIMIT 10000;

-- ШАГ 1.2: Создание составного B-tree индекса
-- Индекс начинается с колонки status_id (высокая селективность), затем дата и вес.
CREATE INDEX idx_transport_filter_composite
ON item_transportation(status_id, transport_date, weight, distance);

-- ШАГ 1.3: Замер с индексом
EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
SELECT transport_id, item_name, transport_date, weight, distance, comment
FROM item_transportation
WHERE transport_date >= '2023-01-01'
  AND weight > 1000
  AND distance > 1000
  AND status_id = 2
LIMIT 10000;

-- ШАГ 1.4: Альтернативный порядок колонок в индексе
DROP INDEX IF EXISTS idx_transport_filter_composite;
CREATE INDEX idx_transport_optimized 
ON item_transportation (transport_date, status_id, weight, distance);

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
SELECT transport_id, item_name, transport_date, weight, distance, comment
FROM item_transportation
WHERE transport_date >= '2023-01-01'
  AND weight > 1000
  AND distance > 1000
  AND status_id = 2
LIMIT 10000;




-- =========================================================================
-- ЗАПРОС 2: Соединение таблиц (JOIN) с фильтрацией
-- Задача: найти отгрузки за последние 30 дней с определенным статусом.
-- =========================================================================

-- ШАГ 2.1: Без индексов
DROP INDEX IF EXISTS idx_transport_date, idx_transport_coop, idx_shipment_date, idx_shipment_status, idx_shipment_transport;
DROP INDEX IF EXISTS idx_transport_coop_date, idx_shipment_date_status, idx_shipment_status_date;

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
SELECT
    t.transport_id, t.item_name, t.transport_date, t.weight,
    s.shipment_date, s.tracking_number, s.inspector,
    c.title AS coop_name -- Исправлено: в таблице coop колонка называется title
FROM item_transportation t
JOIN shipped_item s ON t.transport_id = s.transport_id
JOIN coop c ON t.coop_id = c.coop_id
WHERE t.transport_date >= CURRENT_DATE - INTERVAL '30 days'
  AND s.shipment_date >= CURRENT_DATE - INTERVAL '30 days'
  AND s.status_id = 2
  AND t.coop_id IN (1, 3, 5)
ORDER BY s.shipment_date DESC
LIMIT 5000;

-- ШАГ 2.2: Одиночные B-tree индексы
CREATE INDEX idx_transport_date ON item_transportation (transport_date);
CREATE INDEX idx_transport_coop ON item_transportation (coop_id);
CREATE INDEX idx_shipment_date ON shipped_item (shipment_date);
CREATE INDEX idx_shipment_status ON shipped_item (status_id);
CREATE INDEX idx_shipment_transport ON shipped_item (transport_id);

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
-- (Тот же SELECT запрос, что и выше)

-- ШАГ 2.3: Составные индексы
DROP INDEX IF EXISTS idx_transport_date, idx_transport_coop, idx_shipment_date, idx_shipment_status, idx_shipment_transport;

CREATE INDEX idx_transport_coop_date ON item_transportation (coop_id, transport_date);
CREATE INDEX idx_shipment_date_status ON shipped_item (shipment_date, status_id);

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
-- (Тот же SELECT запрос, что и выше)

-- ШАГ 2.4: Покрывающие индексы (INCLUDE)
CREATE INDEX idx_transport_optimal ON item_transportation
(coop_id, transport_date, transport_id)
INCLUDE (item_name, weight);

CREATE INDEX idx_shipment_optimal ON shipped_item
(shipment_date DESC, status_id, transport_id)
INCLUDE (tracking_number, inspector);

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
-- (Тот же SELECT запрос, что и выше)


-- =========================================================================
-- ЗАПРОС 3: Полнотекстовый поиск
-- Задача: найти комментарии, содержащие слова "груз", "транспортировка" и "срочный".
-- =========================================================================

-- ШАГ 3.1: Без индексов
DROP INDEX IF EXISTS idx_transport_comment_gin;

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
SELECT transport_id, item_name, transport_date, comment
FROM item_transportation
WHERE to_tsvector('russian', comment) @@ to_tsquery('russian', 'груз & транспортировка & срочный')
LIMIT 10000;

-- ШАГ 3.2: Создание GIN индекса
CREATE INDEX idx_transport_comment_gin ON item_transportation
USING gin(to_tsvector('russian', comment));

EXPLAIN (ANALYZE, VERBOSE, COSTS, TIMING, BUFFERS)
SELECT transport_id, item_name, transport_date, comment
FROM item_transportation
WHERE to_tsvector('russian', comment) @@ to_tsquery('russian', 'груз & транспортировка & срочный')
LIMIT 10000;

-- ШАГ 3.3: Частичный GIN индекс (только для непустых комментариев)
-- Экономит место на диске, так как индексирует только строки с текстом.
CREATE INDEX idx_transport_comment_gin_partial ON item_transportation
USING gin(to_tsvector('russian', comment))
WHERE comment IS NOT NULL AND length(comment) > 0;