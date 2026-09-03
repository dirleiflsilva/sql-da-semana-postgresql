-- Recria somente o ambiente do episódio 07.
DROP SCHEMA IF EXISTS sql_semana_07 CASCADE;
CREATE SCHEMA sql_semana_07;
SET search_path TO sql_semana_07;

CREATE TABLE categories (
    category_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id bigint NOT NULL REFERENCES categories,
    name        text NOT NULL,
    sales_count integer NOT NULL DEFAULT 0
);
