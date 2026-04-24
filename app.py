from flask import Flask, render_template, request
import psycopg2
import os

app = Flask(__name__)

def get_db_connection():
    db_url = os.environ.get('DATABASE_URL', 'postgresql://task6_vvyr_user:h353qcke9sh9sX5wf2VrDFkWX7KNGPca@dpg-d7lj80reo5us73dlqua0-a.ohio-postgres.render.com/task6_vvyr')
    return psycopg2.connect(db_url)

@app.route('/')
def index():
    locale = request.args.get('locale', 'en_US')
    seed = int(request.args.get('seed', 12345))
    batch_idx = int(request.args.get('batch_idx', 1))
    batch_size = int(request.args.get('batch_size', 10))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM generate_fake_users(%s, %s, %s, %s)",
            (seed, locale, batch_idx, batch_size)
        )
        users = cursor.fetchall()
        cursor.close()
        conn.close()
    except Exception as e:
        return f"Database connection error: {e}"

    return render_template('index.html', users=users, locale=locale, seed=seed, batch_idx=batch_idx)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port)