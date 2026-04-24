import psycopg2
from faker import Faker

def seed_database():
    conn = psycopg2.connect(host="localhost", database="task6", user="postgres", password="postgres")
    cursor = conn.cursor()

    fake_en = Faker('en_US')
    fake_de = Faker('de_DE')

    locales = [
        ('en_US', fake_en),
        ('de_DE', fake_de)
    ]

    for locale_code, fake in locales:
        first_names = list(set([fake.first_name() for _ in range(200)]))[:150]
        last_names = list(set([fake.last_name() for _ in range(200)]))[:150]
        middle_names = list(set([fake.first_name() for _ in range(200)]))[:150]
        cities = list(set([fake.city() for _ in range(200)]))[:150]
        streets = list(set([fake.street_name() for _ in range(200)]))[:150]

        for name in first_names:
            cursor.execute("INSERT INTO names (locale, name_type, value) VALUES (%s, 'FIRST', %s)", (locale_code, name))
        for name in last_names:
            cursor.execute("INSERT INTO names (locale, name_type, value) VALUES (%s, 'LAST', %s)", (locale_code, name))
        for name in middle_names:
            cursor.execute("INSERT INTO names (locale, name_type, value) VALUES (%s, 'MIDDLE', %s)", (locale_code, name))

        for city in cities:
            cursor.execute("INSERT INTO locations (locale, location_type, value) VALUES (%s, 'CITY', %s)", (locale_code, city))
        for street in streets:
            cursor.execute("INSERT INTO locations (locale, location_type, value) VALUES (%s, 'STREET', %s)", (locale_code, street))

    conn.commit()
    cursor.close()
    conn.close()

if __name__ == '__main__':
    seed_database()