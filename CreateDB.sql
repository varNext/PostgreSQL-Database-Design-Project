DROP TABLE IF EXISTS profile, capital, coop, coop_member, coop_owner, owner_name, owner_passport, 
cargo_type, carrier_company,delivery_status, item_transportation, shipped_item,transport_status CASCADE;

-- Активация расширения Python
CREATE EXTENSION IF NOT EXISTS plpython3u;


-- Создание таблицы специлизации кооператива
CREATE TABLE profile (
    profile_id SERIAL PRIMARY KEY,
    profile_title VARCHAR(150) NOT NULL 
);

-- Создание таблицы уставного капитала
CREATE TABLE capital (
    capital_id  SERIAL PRIMARY KEY,
    share_capital numeric(10,2) CHECK (share_capital > 0) NOT NULL
);

-- Создание таблицы ФИО владельца
CREATE TABLE owner_name (
    name_id  SERIAL PRIMARY KEY,
    name_owner VARCHAR(25) NOT NULL,
    surname_owner VARCHAR(25) NOT NULL,
    patronymic_owner VARCHAR(25)
);

-- Создание таблицы данные паспорта владельца
CREATE TABLE owner_passport (
    passport_id SERIAL PRIMARY KEY,
    seria_pass INT NOT NULL,
    number_pass INT NOT NULL UNIQUE,
    data_pass DATE NOT NULL
);

-- Создание таблицы владелец
CREATE TABLE coop_owner (
    owner_id SERIAL PRIMARY KEY,
    name_id INT NOT NULL,
    passport_id INT NOT NULL,
    address VARCHAR(255),
    owner_location VARCHAR(255),
    CONSTRAINT fk_passport FOREIGN KEY (passport_id) REFERENCES owner_passport (passport_id) ON DELETE CASCADE,
    CONSTRAINT fk_name FOREIGN KEY (name_id) REFERENCES owner_name (name_id) ON DELETE CASCADE
);

-- Создание таблицы кооператив
CREATE TABLE coop (
    coop_id SERIAL PRIMARY KEY,
    profile_id INT NOT NULL,
    capital_id INT NOT NULL,
    worker INT,
    district VARCHAR(255),
    title VARCHAR(255) UNIQUE,
    CONSTRAINT fk_profile FOREIGN KEY (profile_id) REFERENCES profile (profile_id),
    CONSTRAINT fk_capital FOREIGN KEY (capital_id) REFERENCES capital (capital_id)
);

-- Создание таблицы членства
CREATE TABLE coop_member (
    memr_id SERIAL PRIMARY KEY,
    number_reg INT NOT NULL,
    rate REAL, 
    date DATE,
    coop_id INT NOT NULL,
    owner_id INT NOT NULL,
    CONSTRAINT fk_coop FOREIGN KEY (coop_id) REFERENCES coop (coop_id) ON DELETE CASCADE,
    CONSTRAINT fk_mem FOREIGN KEY (owner_id) REFERENCES coop_owner (owner_id) ON DELETE CASCADE
);

--Заполнение таблицы profile
INSERT INTO profile (profile_title) VALUES
('Химическая промышленность'),
('Текстильная промышленность'),
('Металлургическая промышленность'),
('Агропромышленность'),
('Ядерная промышленность'),
('Нанотехнология'); 

--Заполнение таблицы capital
INSERT INTO capital (share_capital) VALUES
(1000.00),
(10000.00),
(50000.00),
(100000.00);

--Заполнение таблицы owner_name
INSERT INTO owner_name (name_owner, surname_owner, patronymic_owner) VALUES
('Артем', 'Орешкин', 'Владимирович'),
('Михаил', 'Картин', 'Владимирович'),
('Людмила', 'Иванова', 'Олеговна'),
('Влада', 'Росси', NULL),
('Артем', 'Гончаров', 'Семенович'),
('Карина', 'Росси', 'Аркадьевна'),
('Арина', 'Орешкина', 'Семеновна'),
('Андрей', 'Гончаров', 'Семенович'),
('Ксения', 'Демьяненко', 'Сергеевна');

--Заполнение таблицы owner_passport
INSERT INTO owner_passport (seria_pass, number_pass, data_pass) VALUES
(3222, 369423, '2019-11-23'),  -- passport_id = 1
(3225, 369596, '2020-02-11'),  -- passport_id = 2
(3228, 369578, '2018-11-18'),  -- passport_id = 3
(3227, 369594, '2013-08-14'),  -- passport_id = 4
(3225, 369592, '2014-02-14'),  -- passport_id = 5
(3225, 369782, '2019-11-22'),  -- passport_id = 6
(3227, 369523, '2013-10-15'),  -- passport_id = 7
(3225, 369751, '2015-12-26'),  -- passport_id = 8
(3225, 369452, '2021-11-22');  -- passport_id = 9

--Заполнение таблицы coop_owner
INSERT INTO coop_owner (name_id, passport_id, address, owner_location) VALUES
(1, 6, 'ул.Коломенная, д.5', 'Камский район'),
(2, 1, 'ул.Коломенная, д.5', 'Камский район'),
(3, 4, 'ул.Бежневой, д.81', 'Петровский район'),
(4, 3, 'ул.Дунайская, д.8', 'Среднеостровский район'),
(5, 5, 'ул.Полевая, д.11', 'Васильевский район'),
(6, 2, 'ул.Коломенная, д.5', 'Камский район'),
(7, 9, 'ул.Патришева, д.8', 'Калицкий район'),
(8, 8, 'ул.Моркотова, д.37', 'Васильевский район'),
(9, 7, 'ул.Коломенная, д.5', 'Калицкий район');

--Заполнение таблицы coop
INSERT INTO coop (title, profile_id, capital_id, worker, district) VALUES
('Энфис', 1, 1, 500, 'Среднеостровский район'),
('Капрос', 2, 2, 24, 'Васильевский район'),
('Лого', 3, 3, 1000, 'Камский район'),
('Элерм', 2, 2, 35, 'Среднеостровский район'),
('Магнем', 4, 4, 1000, 'Петровский район'),
('Кармо', 5, 4, 550, 'Камский район'),
('Эпсилон', 4, 3, 1000, 'Камский район'),
('Энигма', 2, 2, 35, 'Калицкий район'),
('Прометей', 1, 4, 1000, 'Калицкий район');

--Заполнение таблицы coop_member
INSERT INTO coop_member (number_reg, rate, date, coop_id, owner_id) VALUES
(125, 0.2, '2024-08-01', 1, 1),  -- owner_id 1
(256, 0.9, '2023-12-12', 2, 2),  -- owner_id 2
(450, 0.6, '2025-02-01', 3, 3),  -- owner_id 3
(32, 1.0, '2023-09-11', 4, 4),   -- owner_id 4
(178, 1.0, '2024-11-24', 5, 5),  -- owner_id 5
(126, 0.5, '2020-08-02', 6, 6),  -- owner_id 6
(127, 0.5, '2021-05-02', 7, 7),  -- owner_id 7
(146, 0.3, '2024-08-03', 8, 8);  -- owner_id 8


--НОВЫЕ ТАБЛИЦЫ
-- Таблица для перевозок (10+ млн записей)
CREATE TABLE item_transportation (
    transport_id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    transport_date DATE NOT NULL,
    weight NUMERIC(10,2) CHECK (weight > 0),
    distance INTEGER CHECK (distance > 0),
    status VARCHAR(20) CHECK (status IN ('pending', 'in_transit', 'delivered', 'cancelled')),
    comment TEXT, -- Для полнотекстового поиска (~1000 слов)
    coop_id INTEGER REFERENCES coop(coop_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица отгрузок (1+ млн записей)
CREATE TABLE shipped_item (
    shipment_id SERIAL PRIMARY KEY,
    transport_id INTEGER NOT NULL,
    shipment_date DATE NOT NULL,
    quantity INTEGER CHECK (quantity > 0),
    tracking_number VARCHAR(50) UNIQUE,
    inspector VARCHAR(100),
    shipment_status VARCHAR(20) CHECK (shipment_status IN ('prepared', 'shipped', 'received')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица статусов (5-10 записей)
CREATE TABLE transport_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(20) UNIQUE NOT NULL,
    description TEXT
);

-- Таблица типов грузов (5-10 записей)
CREATE TABLE cargo_type (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    risk_level VARCHAR(10)
);

-- Заполнение таблицы статусов
INSERT INTO transport_status (status_name, description) VALUES
('pending', 'Ожидает обработки'),
('in_transit', 'В пути'),
('delivered', 'Доставлен'),
('cancelled', 'Отменен');

-- Заполнение таблицы типов грузов
INSERT INTO cargo_type (type_name, risk_level) VALUES
('Химикаты', 'high'),
('Текстиль', 'low'),
('Металлы', 'medium'),
('Продукты питания', 'medium'),
('Электроника', 'high'),
('Строительные материалы', 'low'),
('Медицинское оборудование', 'high'),
('Мебель', 'low'),
('Автозапчасти', 'medium'),
('Сельхоз продукция', 'low');

-- Заполнение таблицы статусов отгрузок
INSERT INTO transport_status (status_name, description) VALUES
('prepared', 'Подготовлен к отправке'),
('shipped', 'Отправлен'),
('received', 'Получен');

-- Добавляем недостающие столбцы для связей
ALTER TABLE item_transportation 
ADD COLUMN IF NOT EXISTS cargo_type_id INTEGER REFERENCES cargo_type(type_id),
ADD COLUMN IF NOT EXISTS status_id INTEGER REFERENCES transport_status(status_id);

ALTER TABLE shipped_item 
ADD COLUMN IF NOT EXISTS status_id INTEGER REFERENCES transport_status(status_id);


--------------
----Скрипт-генератор хранимой функции с использованием plpython3u для таблиц аналитической БД
---------------
CREATE OR REPLACE FUNCTION generate_massive_data(
    transport_count INTEGER DEFAULT 10000000,
    shipment_count INTEGER DEFAULT 1000000,
    batch_size INTEGER DEFAULT 10000 
RETURNS
TEXT
AS $$
import random
from datetime import datetime, timedelta

--генерирование комментариев
def generate_comment():
    """Генератор текста комментария ~1000 слов"""
    words = [
        'груз', 'транспортировка', 'логистика', 'доставка', 'отправка',
        'получение', 'склад', 'перевозка', 'маршрут', 'транспорт',
        'кооператив', 'партнер', 'клиент', 'поставка', 'заказ',
        'товар', 'материал', 'продукция', 'оборудование', 'инструмент',
        'срочный', 'обычный', 'специальный', 'опасный', 'хрупкий',
        'тяжелый', 'легкий', 'габаритный', 'мелкий', 'стандартный',
        'требуется', 'необходимо', 'обязательно', 'рекомендуется', 'желательно',
        'качество', 'количество', 'срок', 'время', 'дата',
        'документы', 'сертификаты', 'разрешения', 'лицензии', 'договор',
        'оплата', 'расчет', 'стоимость', 'цена', 'бюджет'
    ]

    # Генерируем ~1000 слов
    comment_words = []
    for _ in range(950 + random.randint(0, 100)):
        comment_words.append(random.choice(words))

    # Дополнение стандартных фраз
    sentences = [
        "Особые условия транспортировки требуют внимательного подхода.",
        "Необходимо соблюдать температурный режим и условия хранения.",
        "Товар требует специальной упаковки и маркировки.",
        "Срочная доставка в соответствии с договоренностями.",
        "Координация с получателем обязательна перед доставкой."
    ]

    # Добавление несколько предложений
    for _ in range(3):
        comment_words.append(random.choice(sentences))

    return ' '.join(comment_words)


def generate_transportation_batch(batch_size, start_id, coop_ids, statuses, cargo_types):
    """Генерация batch записей для item_transportation"""
    batch = []
    current_date = datetime.now()

    items = ['Химические реактивы', 'Ткани хлопковые', 'Металлопрокат',
             'Продукты сельхоз', 'Электронные компоненты', 'Строительные блоки',
             'Медицинские препараты', 'Офисная мебель', 'Автомобильные детали',
             'Зерновые культуры']

    for i in range(batch_size):
        transport_date = current_date - timedelta(days=random.randint(1, 3650))
        batch.append({
            'item_name': random.choice(items),
            'transport_date': transport_date.strftime('%Y-%m-%d'),
            'weight': round(random.uniform(1.0, 10000.0), 2),
            'distance': random.randint(10, 5000),
            'status': random.choice(statuses),
            'comment': generate_comment(),
            'coop_id': random.choice(coop_ids),
            'cargo_type_id': random.choice(cargo_types),
            'status_id': random.randint(1, 4)  # соответствие transport_status
        })

    return batch


def generate_shipment_batch(batch_size, start_id, transport_ids):
    """Генерация batch записей для shipped_item"""
    batch = []
    current_date = datetime.now()
    inspectors = ['Иванов И.И.', 'Петров П.П.', 'Сидоров С.С.', 'Кузнецов К.К.', None]
    statuses = ['prepared', 'shipped', 'received']

    for i in range(batch_size):
        shipment_date = current_date - timedelta(days=random.randint(1, 365))
        batch.append({
            'transport_id': random.choice(transport_ids),
            'shipment_date': shipment_date.strftime('%Y-%m-%d'),
            'quantity': random.randint(1, 100),
            'tracking_number': f"TRK{random.randint(1000000000, 9999999999)}",
            'inspector': random.choice(inspectors),
            'shipment_status': random.choice(statuses),
            'status_id': random.randint(5, 7)  # соответствие дополнительным статусам
        })

    return batch


try:
    # Получаем ID кооперативов
    coop_result = plpy.execute("SELECT coop_id FROM coop")
    coop_ids = [row['coop_id'] for row in coop_result]

    # Получаем ID типов грузов
    cargo_result = plpy.execute("SELECT type_id FROM cargo_type")
    cargo_types = [row['type_id'] for row in cargo_result]

    # Статусы для транспортировки
    statuses = ['pending', 'in_transit', 'delivered', 'cancelled']

    total_generated = {
        'transportation': 0,
        'shipments': 0
    }

    # Генерация данных для item_transportation (10+ млн)
    plpy.notice("Начало генерации {} записей в item_transportation...".format(transport_count))

    for batch_start in range(0, transport_count, batch_size):
        current_batch_size = min(batch_size, transport_count - batch_start)

        # Генерируем batch данных
        batch_data = generate_transportation_batch(current_batch_size, batch_start, coop_ids, statuses, cargo_types)

        # Формируем SQL запрос для batch вставки
        values = []
        for item in batch_data:
            values.append("('{}', '{}', {}, {}, '{}', '{}', {}, {}, {})".format(
                item['item_name'].replace("'", "''"),
                item['transport_date'],
                item['weight'],
                item['distance'],
                item['status'],
                item['comment'].replace("'", "''"),
                item['coop_id'],
                item['cargo_type_id'],
                item['status_id']
            ))

        insert_query = """
            INSERT INTO item_transportation 
            (item_name, transport_date, weight, distance, status, comment, coop_id, cargo_type_id, status_id)
            VALUES {}
        """.format(','.join(values))

        # Выполняем вставку
        plpy.execute(insert_query)
        total_generated['transportation'] += current_batch_size

        if batch_start % 100000 == 0:
            plpy.notice("Сгенерировано {} записей транспортировки".format(total_generated['transportation']))

    plpy.notice("Завершена генерация {} записей в item_transportation".format(total_generated['transportation']))

    # Генерация данных для shipped_item (1+ млн)
    plpy.notice("Начало генерации {} записей в shipped_item...".format(shipment_count))

    # Получаем существующие transport_id
    transport_result = plpy.execute("SELECT transport_id FROM item_transportation LIMIT 1000000")
    transport_ids = [row['transport_id'] for row in transport_result]

    for batch_start in range(0, shipment_count, batch_size):
        current_batch_size = min(batch_size, shipment_count - batch_start)

        # Генерируем batch данных
        batch_data = generate_shipment_batch(current_batch_size, batch_start, transport_ids)

        # Формируем SQL запрос для batch вставки
        values = []
        for item in batch_data:
            inspector_value = "'{}'".format(item['inspector'].replace("'", "''")) if item['inspector'] else 'NULL'

            values.append("({}, '{}', {}, '{}', {}, '{}', {})".format(
                item['transport_id'],
                item['shipment_date'],
                item['quantity'],
                item['tracking_number'],
                inspector_value,
                item['shipment_status'],
                item['status_id']
            ))

        insert_query = """
            INSERT INTO shipped_item 
            (transport_id, shipment_date, quantity, tracking_number, inspector, shipment_status, status_id)
            VALUES {}
        """.format(','.join(values))

        # Выполняем вставку
        plpy.execute(insert_query)
        total_generated['shipments'] += current_batch_size

        if batch_start % 100000 == 0:
            plpy.notice("Сгенерировано {} записей отгрузок".format(total_generated['shipments']))

    plpy.notice("Завершена генерация {} записей в shipped_item".format(total_generated['shipments']))

    return "Успешно сгенерировано: {} записей транспортировки и {} записей отгрузок".format(
        total_generated['transportation'], total_generated['shipments'])

except Exception as e:
    plpy.error("Ошибка при генерации данных: {}".format(str(e)))

$$ LANGUAGE
plpython3u;

-- Проверка работы полнотекстового поиска
CREATE OR REPLACE FUNCTION test_fulltext_search(search_term TEXT)
RETURNS TABLE(transport_id INT, item_name VARCHAR, comment_preview TEXT, rank REAL)
AS $$
BEGIN
RETURN QUERY
SELECT it.transport_id,
       it.item_name,
       substring(it.comment from 1 for 100) as comment_preview,
       ts_rank(to_tsvector('russian', it.comment), plainto_tsquery('russian', search_term)) as rank
FROM item_transportation it
WHERE to_tsvector('russian', it.comment) @ @ plainto_tsquery('russian', search_term)
ORDER BY rank DESC
LIMIT 10;
END;
$$ LANGUAGE
plpgsql;

-- Вызов процедуры генерации
CREATE EXTENSION IF NOT EXISTS plpython3u;

SELECT generate_massive_data(100000, 10000, 1000); -- Тестовый прогон
--SELECT generate_massive_data(10000000, 1000000, 10000); -- Полная генерация
