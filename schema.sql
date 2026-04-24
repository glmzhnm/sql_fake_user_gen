CREATE TABLE names (
    id SERIAL PRIMARY KEY,
    locale VARCHAR(10),
    name_type VARCHAR(10),
    value VARCHAR(50)
);

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    locale VARCHAR(10),
    location_type VARCHAR(10),
    value VARCHAR(50)
);

CREATE INDEX idx_names_locale ON names(locale, name_type);
CREATE INDEX idx_locations_locale ON locations(locale, location_type);
CREATE OR REPLACE FUNCTION random_normal(u1 FLOAT, u2 FLOAT, mean FLOAT, stddev FLOAT)
RETURNS FLOAT AS $$
BEGIN
    IF u1 = 0 THEN u1 := 0.000001; END IF;
    RETURN mean + (SQRT(-2.0 * LN(u1)) * COS(2.0 * PI() * u2)) * stddev;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION random_coordinates(u1 FLOAT, u2 FLOAT, OUT lat FLOAT, OUT lon FLOAT) AS $$
BEGIN
    lon := (u1 * 360.0) - 180.0;
    lat := DEGREES(ASIN(2.0 * u2 - 1.0));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION get_random_element(p_locale VARCHAR, p_type VARCHAR, rand_val FLOAT, p_table VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    result VARCHAR;
    row_count INT;
BEGIN
    IF p_table = 'names' THEN
        SELECT COUNT(*) INTO row_count FROM names WHERE locale = p_locale AND name_type = p_type;
        SELECT value INTO result FROM names WHERE locale = p_locale AND name_type = p_type
        OFFSET FLOOR(rand_val * row_count) LIMIT 1;
    ELSIF p_table = 'locations' THEN
        SELECT COUNT(*) INTO row_count FROM locations WHERE locale = p_locale AND location_type = p_type;
        SELECT value INTO result FROM locations WHERE locale = p_locale AND location_type = p_type
        OFFSET FLOOR(rand_val * row_count) LIMIT 1;
    END IF;
    RETURN result;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION prng(seed INT, record_idx INT, salt INT)
RETURNS FLOAT AS $$
DECLARE
    combined_text TEXT;
    hash_val BIGINT;
BEGIN
    combined_text := seed::TEXT || '-' || record_idx::TEXT || '-' || salt::TEXT;

    RETURN ABS(hashtext(combined_text)) / 2147483647.0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION generate_fake_users(p_seed INT, p_locale VARCHAR, p_batch_idx INT, p_batch_size INT)
RETURNS TABLE (
    full_name VARCHAR, address VARCHAR, phone VARCHAR, email VARCHAR,
    latitude FLOAT, longitude FLOAT, height_cm INT, eye_color VARCHAR
) AS $$
DECLARE
    i INT;
    abs_idx INT;
    f_name VARCHAR; l_name VARCHAR; m_name VARCHAR;
    city VARCHAR; street VARCHAR;
    u1 FLOAT; u2 FLOAT; rand_val FLOAT;
BEGIN
    FOR i IN 1..p_batch_size LOOP
        abs_idx := (p_batch_idx - 1) * p_batch_size + i;

        f_name := get_random_element(p_locale, 'FIRST', prng(p_seed, abs_idx, 10), 'names');
        l_name := get_random_element(p_locale, 'LAST', prng(p_seed, abs_idx, 11), 'names');
        rand_val := prng(p_seed, abs_idx, 12);

        IF rand_val < 0.3 THEN -- 30% chance for a middle name
            m_name := get_random_element(p_locale, 'MIDDLE', prng(p_seed, abs_idx, 13), 'names');
            full_name := f_name || ' ' || m_name || ' ' || l_name;
        ELSIF rand_val < 0.5 AND p_locale = 'en_US' THEN -- 20% chance for title in US
            full_name := 'Dr. ' || f_name || ' ' || l_name;
        ELSE
            full_name := f_name || ' ' || l_name;
        END IF;

        city := get_random_element(p_locale, 'CITY', prng(p_seed, abs_idx, 20), 'locations');
        street := get_random_element(p_locale, 'STREET', prng(p_seed, abs_idx, 21), 'locations');
        IF p_locale = 'de_DE' THEN
            address := street || ' ' || FLOOR(prng(p_seed, abs_idx, 22) * 200 + 1)::VARCHAR || ', ' || city;
        ELSE
            address := FLOOR(prng(p_seed, abs_idx, 22) * 9000 + 100)::VARCHAR || ' ' || street || ', ' || city;
        END IF;

        SELECT * INTO latitude, longitude FROM random_coordinates(prng(p_seed, abs_idx, 30), prng(p_seed, abs_idx, 31));

        u1 := prng(p_seed, abs_idx, 40);
        u2 := prng(p_seed, abs_idx, 41);
        height_cm := ROUND(random_normal(u1, u2, 170.0, 15.0));

        rand_val := prng(p_seed, abs_idx, 42);
        eye_color := CASE WHEN rand_val < 0.4 THEN 'Brown' WHEN rand_val < 0.7 THEN 'Blue' WHEN rand_val < 0.9 THEN 'Green' ELSE 'Hazel' END;

        email := LOWER(f_name || '.' || l_name || FLOOR(prng(p_seed, abs_idx, 50)*1000)::VARCHAR || '@example.com');
        IF p_locale = 'de_DE' THEN
            phone := '+49 151 ' || FLOOR(prng(p_seed, abs_idx, 60) * 8999999 + 1000000)::VARCHAR;
        ELSE
            phone := '+1 (' || FLOOR(prng(p_seed, abs_idx, 61) * 800 + 200)::VARCHAR || ') 555-' || FLOOR(prng(p_seed, abs_idx, 62) * 8999 + 1000)::VARCHAR;
        END IF;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;