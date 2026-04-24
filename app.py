from flask import Flask, render_template, request
import psycopg2

app = Flask(__name__)


def get_db_connection():
    return psycopg2.connect(host="localhost", database="task6", user="postgres", password="postgres")


@app.route('/')
def index():
    locale = request.args.get('locale', 'en_US')
    seed = int(request.args.get('seed', 12345))
    batch_idx = int(request.args.get('batch_idx', 1))
    batch_size = int(request.args.get('batch_size', 10))

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM generate_fake_users(%s, %s, %s, %s)",
        (seed, locale, batch_idx, batch_size)
    )
    users = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('index.html', users=users, locale=locale, seed=seed, batch_idx=batch_idx)


if __name__ == '__main__':
    app.run(debug=True)