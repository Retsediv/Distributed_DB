import time
from multiprocessing import Process
from typing import Optional

import psycopg2

WRITES = 10_000


def timer(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start
        wrapper.total_time += duration
        print(f"Execution time: {duration}")
        return result

    wrapper.total_time = 0
    return wrapper


conn = psycopg2.connect(
    "dbname=db user=user password=password host=localhost port=5432"
)


def create_table():
    # check if table exists
    cursor = conn.cursor()
    cursor.execute(
        "SELECT * FROM information_schema.tables WHERE table_name='user_counter';"
    )
    if cursor.fetchone():
        print("Table already exists")
        return

    # create table
    cursor.execute(
        "CREATE TABLE user_counter (user_id serial PRIMARY KEY, counter integer, version integer);"
    )
    if cursor.rowcount == 0:
        print("Table created")
    conn.commit()

    # insert data
    cursor.execute(
        "INSERT INTO user_counter (user_id, counter, version) VALUES (1, 0, 0);"
    )
    conn.commit()
    cursor.close()


def set_to_initial_value():
    cursor = conn.cursor()
    cursor.execute("UPDATE user_counter SET counter = 0 WHERE user_id = 1;")
    conn.commit()
    cursor.close()


def select_counter_value() -> Optional[int]:
    cursor = conn.cursor()
    cursor.execute("SELECT counter FROM user_counter WHERE user_id = 1;")
    counter = cursor.fetchone()
    cursor.close()
    return None if counter is None else counter[0]


# Part 1
def lost_update():
    cursor = conn.cursor()
    for _ in range(0, WRITES):
        cursor.execute("SELECT counter FROM user_counter WHERE user_id = 1;")
        counter = cursor.fetchone()[0]
        counter += 1
        cursor.execute(
            "UPDATE user_counter SET counter = %s WHERE user_id = %s;", (counter, 1)
        )
        conn.commit()
    cursor.close()


# Part 2
def in_place_update():
    cursor = conn.cursor()
    for _ in range(0, WRITES):
        cursor.execute(
            "UPDATE user_counter SET counter = counter + 1 WHERE user_id = %s;", (1,)
        )
        conn.commit()
    cursor.close()


# Part 3
def row_level_locking():
    current_conn = psycopg2.connect(
        "dbname=db user=user password=password host=localhost port=5432"
    )

    cursor = current_conn.cursor()
    for _ in range(0, WRITES):
        cursor.execute("SELECT counter FROM user_counter WHERE user_id = 1 FOR UPDATE;")
        counter = cursor.fetchone()[0]
        counter += 1
        cursor.execute(
            "UPDATE user_counter SET counter = %s WHERE user_id = %s;", (counter, 1)
        )
        current_conn.commit()
    cursor.close()


# Part 4
def optimistic_concurrency_control():
    cursor = conn.cursor()
    for i in range(0, WRITES):
        if i % 100 == 0:
            print(f"Write {i}")

        while True:
            cursor.execute(
                "SELECT counter, version FROM user_counter WHERE user_id = 1;"
            )
            counter, version = cursor.fetchone()
            counter += 1
            cursor.execute(
                "UPDATE user_counter SET counter = %s, version = %s WHERE user_id = %s AND version = %s;",
                (counter, version + 1, 1, version),
            )
            conn.commit()
            count = cursor.rowcount
            if (count > 0):
                break

    cursor.close()


@timer
def run_experiment(fn):
    processes = []
    for _ in range(10):
        process = Process(target=fn)
        processes.append(process)
        process.start()

    for process in processes:
        process.join()


def main():
    print("[Creating a table]")

    create_table()
    set_to_initial_value()
    counter = select_counter_value()
    print(f"Counter value: {counter}")

    # # ---------------- Part 1
    # print("\n[Lost update]")
    # set_to_initial_value()
    #
    # run_experiment(lost_update)
    # counter = select_counter_value()
    # print(f"Counter value: {counter}")
    #
    # # ---------------- Part 1.1
    # print("\n[Lost update | SERIALIZABLE]")
    # set_to_initial_value()
    #
    # conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_SERIALIZABLE)
    # run_experiment(lost_update)
    # conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_DEFAULT)
    #
    # counter = select_counter_value()
    # print(f"Counter value: {counter}")
    #
    # # ---------------- Part 2
    # print("\n[IN-PLACE UPDATE]")
    # set_to_initial_value()
    #
    # run_experiment(in_place_update)
    # counter = select_counter_value()
    # print(f"Counter value: {counter}")
    #
    # # ---------------- Part 3
    # print("\n[ROW-LEVEL LOCKING]")
    # set_to_initial_value()
    #
    # run_experiment(row_level_locking)
    # counter = select_counter_value()
    # print(f"Counter value: {counter}")
    #
    # ---------------- Part 4
    print("\n[OPTIMISTIC CONCURRENCY CONTROL]")
    set_to_initial_value()

    run_experiment(optimistic_concurrency_control)
    counter = select_counter_value()
    print(f"Counter value: {counter}")


if __name__ == "__main__":
    main()
    conn.close()
