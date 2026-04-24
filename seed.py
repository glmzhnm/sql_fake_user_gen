import psycopg2
from faker import Faker
from psycopg2.extras import execute_values


def seed_database():
    db_url = "postgresql://task6_vvyr_user:h353qcke9sh9sX5wf2VrDFkWX7KNGPca@dpg-d7lj80reo5us73dlqua0-a.ohio-postgres.render.com/task6_vvyr?sslmode=require"

    conn = psycopg2.connect(db_url)
    cursor = conn.cursor()

    cursor.execute("TRUNCATE names, locations RESTART IDENTITY;")

    fake_en = Faker('en_US')
    fake_de = Faker('de_DE')

    locales = [
        ('en_US', fake_en),
        ('de_DE', fake_de)
    ]

    for locale_code, fake in locales:
        first_names = [(locale_code, 'FIRST', n) for n in {fake.first_name() for _ in range(200)}]
        last_names = [(locale_code, 'LAST', n) for n in {fake.last_name() for _ in range(200)}]
        middle_names = [(locale_code, 'MIDDLE', n) for n in {fake.first_name() for _ in range(200)}]

        cities = [(locale_code, 'CITY', c) for c in {fake.city() for _ in range(200)}]
        streets = [(locale_code, 'STREET', s) for s in {fake.street_name() for _ in range(200)}]

        execute_values(cursor, "INSERT INTO names (locale, name_type, value) VALUES %s", first_names)
        execute_values(cursor, "INSERT INTO names (locale, name_type, value) VALUES %s", last_names)
        execute_values(cursor, "INSERT INTO names (locale, name_type, value) VALUES %s", middle_names)

        execute_values(cursor, "INSERT INTO locations (locale, location_type, value) VALUES %s", cities)
        execute_values(cursor, "INSERT INTO locations (locale, location_type, value) VALUES %s", streets)

    conn.commit()
    cursor.close()
    conn.close()


if __name__ == '__main__':
    seed_database()