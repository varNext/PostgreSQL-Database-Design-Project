-- =========================================================================
-- ОПТИМИЗАЦИЯ ТАБЛИЦЫ НА 10 МЛН+ СТРОК (ПАРТИЦИОНИРОВАНИЕ)
-- =========================================================================
-- В этом файле описаны:
-- 1. Схема партиционирования (RANGE по датам).
-- 2. Функции автосоздания и архивации партиций.
-- 3. Настройки для быстрой массовой вставки.
-- 4. Материализованные представления для быстрых агрегаций.
-- 5. Функции мониторинга и обслуживания.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 0. ПОДГОТОВКА: СОЗДАНИЕ РОДИТЕЛЬСКОЙ ПАРТИЦИОНИРОВАННОЙ ТАБЛИЦЫ
-- -------------------------------------------------------------------------
-- Примечание: Без этой таблицы все функции ниже упадут с ошибкой.
-- Первичный ключ (PK) ОБЯЗАТЕЛЬНО должен включать колонку, по которой идет партиционирование.

DROP TABLE IF EXISTS item_transportation_partitioned CASCADE;

CREATE TABLE item_transportation_partitioned (
    transport_id SERIAL,
    item_name VARCHAR(100) NOT NULL,
    transport_date DATE NOT NULL,
    weight NUMERIC(10,2) CHECK (weight > 0),
    distance INTEGER CHECK (distance > 0),
    status_id INTEGER,
    comment TEXT,
    coop_id INTEGER,
    cargo_type_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (transport_id, transport_date)
) PARTITION BY RANGE (transport_date);

-- Создаем базовую секцию на текущий год
CREATE TABLE item_transportation_2024 PARTITION OF item_transportation_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Создаем секцию на следующий год
CREATE TABLE item_transportation_2025 PARTITION OF item_transportation_partitioned
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');


-- -------------------------------------------------------------------------
-- 1. АВТОМАТИЧЕСКОЕ СОЗДАНИЕ НОВЫХ СЕКЦИЙ
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_transportation_partitions()
RETURNS void AS $$
DECLARE
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
    next_year INTEGER := current_year + 1;
    partition_exists BOOLEAN;
    partition_table_name TEXT;
BEGIN
    partition_table_name := 'item_transportation_' || next_year;

    -- Проверяем существование секции на следующий год
    SELECT EXISTS(
        SELECT 1 FROM pg_tables
        WHERE tablename = partition_table_name
    ) INTO partition_exists;

    IF NOT partition_exists THEN
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF item_transportation_partitioned
            FOR VALUES FROM (%L) TO (%L)',
            partition_table_name,
            format('%s-01-01', next_year),
            format('%s-01-01', next_year + 1)
        );
        RAISE NOTICE 'Создана секция: %', partition_table_name;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------------
-- 2. АРХИВАЦИЯ СТАРЫХ ДАННЫХ (DETACH PARTITION)
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION archive_old_transportations(retention_years INTEGER DEFAULT 3)
RETURNS bigint AS $$
DECLARE
    cutoff_date DATE := CURRENT_DATE - (retention_years * INTERVAL '1 year');
    archived_count bigint := 0;
    partition_record RECORD;
    year_str TEXT;
    partition_year INTEGER;
BEGIN
    -- ВАЖНО: Используем системное представление pg_inherits вместо pg_partitions,
    -- так как pg_partitions доступно только в расширении pg_partman.
    FOR partition_record IN
        SELECT c.relname AS partition_name
        FROM pg_inherits i
        JOIN pg_class c ON i.inhrelid = c.oid
        JOIN pg_class p ON i.inhparent = p.oid
        WHERE p.relname = 'item_transportation_partitioned'
    LOOP
        IF partition_record.partition_name LIKE 'item_transportation_20%' THEN
            year_str := substring(partition_record.partition_name from 'item_transportation_([0-9]{4})');
            
            IF year_str IS NOT NULL THEN
                partition_year := year_str::INTEGER;
                
                IF partition_year < EXTRACT(YEAR FROM cutoff_date) THEN
                    -- Отсоединяем секцию (это не блокирует основную таблицу)
                    EXECUTE format(
                        'ALTER TABLE item_transportation_partitioned DETACH PARTITION %I',
                        partition_record.partition_name
                    );
                    -- Переименовываем для архива
                    EXECUTE format(
                        'ALTER TABLE %I RENAME TO %I',
                        partition_record.partition_name,
                        'archive_' || partition_record.partition_name
                    );
                    
                    archived_count := archived_count + 1;
                    RAISE NOTICE 'Заархивирована секция: %', partition_record.partition_name;
                END IF;
            END IF;
        END IF;
    END LOOP;
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------------
-- 3. НАСТРОЙКИ ДЛЯ БЫСТРОЙ ВСТАВКИ ДАННЫХ
-- -------------------------------------------------------------------------
-- Примечание: Эти настройки применяются к текущей сессии, а не глобально.
-- Для глобального применения используйте ALTER SYSTEM (требует перезапуска).

SET maintenance_work_mem = '1GB';
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 4;

-- Функция для пакетной вставки (используем UNNEST для скорости вместо циклов)
CREATE OR REPLACE FUNCTION batch_insert_transportations(
    transports_data JSONB -- Передаем данные в JSONB для гибкости
)
RETURNS bigint AS $$
DECLARE
    total_inserted bigint := 0;
BEGIN
    INSERT INTO item_transportation_partitioned (
        item_name, transport_date, weight, distance, status_id, comment, coop_id, cargo_type_id
    )
    SELECT 
        (elem->>'item_name')::varchar,
        (elem->>'transport_date')::date,
        (elem->>'weight')::numeric,
        (elem->>'distance')::integer,
        (elem->>'status_id')::integer,
        elem->>'comment',
        (elem->>'coop_id')::integer,
        (elem->>'cargo_type_id')::integer
    FROM jsonb_array_elements(transports_data) AS elem;
    
    GET DIAGNOSTICS total_inserted = ROW_COUNT;
    RETURN total_inserted;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------------
-- 4. МАТЕРИАЛИЗОВАННЫЕ ПРЕДСТАВЛЕНИЯ ДЛЯ АГРЕГАЦИЙ
-- -------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS mv_transport_stats_daily;

CREATE MATERIALIZED VIEW mv_transport_stats_daily AS
SELECT
    transport_date,
    coop_id,
    COUNT(*) as total_transports,
    SUM(weight) as total_weight,
    AVG(distance) as avg_distance,
    COUNT(DISTINCT cargo_type_id) as unique_cargo_types
FROM item_transportation_partitioned
WHERE transport_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY transport_date, coop_id
WITH DATA;

-- Уникальный индекс обязателен для REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_stats_date_coop ON mv_transport_stats_daily (transport_date, coop_id);

-- Функция для обновления (вызывать по расписанию через pg_cron, а НЕ через триггер)
CREATE OR REPLACE FUNCTION refresh_transport_stats()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_transport_stats_daily;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------------
-- 5. МОНИТОРИНГ И ОБСЛУЖИВАНИЕ
-- -------------------------------------------------------------------------
-- Функция для мониторинга размера секций (используем pg_class.reltuples для скорости)
CREATE OR REPLACE FUNCTION get_partition_sizes()
RETURNS TABLE(
    partition_name TEXT,
    partition_size TEXT,
    approx_row_count BIGINT,
    data_range TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.relname::TEXT AS partition_name,
        pg_size_pretty(pg_relation_size(c.oid)) AS partition_size,
        c.reltuples::BIGINT AS approx_row_count, -- Приблизительное кол-во (без COUNT(*))
        pg_get_expr(c.relpartbound, c.oid) AS data_range
    FROM pg_inherits i
    JOIN pg_class c ON i.inhrelid = c.oid
    JOIN pg_class p ON i.inhparent = p.oid
    WHERE p.relname = 'item_transportation_partitioned'
    ORDER BY c.relname;
END;
$$ LANGUAGE plpgsql;

-- Автоматическое обслуживание
CREATE OR REPLACE FUNCTION maintenance_transportation_table()
RETURNS void AS $$
BEGIN
    -- Создаем новые секции при необходимости
    PERFORM create_transportation_partitions();
    
    -- Архивируем старые данные (оставляем за 3 года)
    PERFORM archive_old_transportations(3);
    
    -- Обновляем статистику
    ANALYZE item_transportation_partitioned;
    
    -- Обновляем материализованное представление
    PERFORM refresh_transport_stats();
END;
$$ LANGUAGE plpgsql;