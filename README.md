# SQL-Based Fake User Data Generator

## Overview
This is a web application designed to generate deterministic, fake user contact information. The core philosophy of this project is to shift 100% of the data generation logic to the database layer using SQL stored procedures, leaving the Python (Flask) backend as a thin delivery layer.

The generator supports multiple locales (English/USA and German/Germany) and ensures full reproducibility via a seed-based Pseudo-Random Number Generator (PRNG).

## Key Features
- **Deterministic Randomness**: Using the same seed, locale, and page index will always yield the exact same dataset.
- **Statistical Accuracy**: 
  - Physical attributes follow a **Normal Distribution**.
  - Geolocation coordinates are uniformly distributed across the **Sphere**.
- **Extensible Schema**: A single-table approach for names and locations to easily add new regions.
- **High Performance**: Optimized for generating large batches (benchmark: ~4,000 users/sec).

## Technical Implementation (The "Faker" Library)

### 1. The PRNG Logic (`prng` function)
Standard `RAND()` functions in SQL are stateful and non-deterministic for specific offsets. I implemented a custom PRNG using `hashtext`. By hashing a combination of the `seed`, `record_index`, and a `salt`, we achieve a stateless flow where any specific user record can be reconstructed instantly without generating the preceding ones.

### 2. Normal Distribution (`random_normal` function)
To make physical attributes like height look realistic, I implemented the **Box-Muller Transform**. It transforms uniform random variables into a Gaussian distribution. 
- **Algorithm**: $Z = \sqrt{-2 \ln(u_1)} \cos(2 \pi u_2)$

### 3. Uniform Spherical Coordinates (`random_coordinates` function)
Naive random floats for latitude and longitude lead to "clustering" at the poles. To ensure a constant Probability Density Function (PDF) on a sphere, I used:
- **Longitude**: $U_1 \times 360 - 180$
- **Latitude**: $\arcsin(2U_2 - 1)$ converted to degrees.

### 4. Modular Procedure Design
The generation logic is split into "small chunks" as requested:
- `get_random_element`: Handles weighted row selection from lookup tables.
- `prng`: The engine for entropy.
- `generate_fake_users`: The main orchestrator that assembles names, addresses, and attributes.

## Performance Benchmark
- **Environment**: PostgreSQL 16 / Local Machine
- **Test Case**: Generation of 1,000 records.
- **Result**: ~251ms execution time.
- **Throughput**: **3,972 users/second**.

## Setup Instructions
1. **Database**: Run `schema.sql` in your PostgreSQL instance to create tables and functions.
2. **Seeding**: Run `python seed.py` to populate lookup tables with base names and cities (uses `Faker` library for initial data).
3. **Run App**: 
   - `pip install Flask psycopg2-binary faker`
   - `python app.py`
4. **Access**: Open `http://127.0.0.1:5000`
