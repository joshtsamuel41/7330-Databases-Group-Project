import configparser
import mysql.connector
import threading
import time

# ==========================================
# CONFIG
# ==========================================

config = configparser.ConfigParser()
config.read("credentials.ini")

DB_CONFIG = {
    "host": config["mysql"]["host"],
    "user": config["mysql"]["user"],
    "password": config["mysql"]["password"],
    "database": config["mysql"]["database"]
}

NUM_THREADS = 20
OPERATIONS_PER_THREAD = 5

# ==========================================
# GLOBAL METRICS
# ==========================================

metrics = {
    "optimistic": {
        "success": 0,
        "errors": 0,
        "deadlocks": 0,
        "timeouts": 0
    },
    "pessimistic": {
        "success": 0,
        "errors": 0,
        "deadlocks": 0,
        "timeouts": 0
    }
}

metric_lock = threading.Lock()


# ==========================================
# DB CONNECTION
# ==========================================

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


# ==========================================
# RESET TEST ENVIRONMENT
# ==========================================

def reset_test_environment():

    try:

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("DELETE FROM transaction_log")
        cursor.execute("DELETE FROM conflict_log")
        cursor.execute("DELETE FROM deadlock_log")

        cursor.execute("""
            UPDATE book_copy
            SET version = 0,
                status = 'Available'
            WHERE copy_id IN (1,2)
        """)

        conn.commit()

    except Exception as e:

        print(f"Reset error: {e}")

        try:
            conn.rollback()
        except:
            pass

    finally:

        try:
            cursor.close()
            conn.close()
        except:
            pass


# ==========================================
# PESSIMISTIC WORKER
# ==========================================

def pessimistic_worker(thread_id):

    conn = get_connection()
    cursor = conn.cursor()

    for i in range(OPERATIONS_PER_THREAD):

        try:

            cursor.callproc(
                "checkout_pessimistic",
                [1]
            )

            with metric_lock:
                metrics["pessimistic"]["success"] += 1

        except Exception as e:

            error_text = str(e)

            with metric_lock:

                metrics["pessimistic"]["errors"] += 1

                if "1205" in error_text:
                    metrics["pessimistic"]["timeouts"] += 1

                if "1213" in error_text:
                    metrics["pessimistic"]["deadlocks"] += 1

            conn.rollback()

    cursor.close()
    conn.close()


# ==========================================
# OPTIMISTIC WORKER
# ==========================================

def optimistic_worker(thread_id):

    conn = get_connection()
    cursor = conn.cursor()

    for i in range(OPERATIONS_PER_THREAD):
        try:

            results = cursor.callproc(
            "checkout_optimistic",
            [1, thread_id, "READ COMMITTED"]
            )

            for result in cursor.stored_results():
                result.fetchall()

            metrics["optimistic"]["success"] += 1

            conn.commit()

        except Exception as e:

            print(f"Optimistic Error: {e}")

            metrics["optimistic"]["errors"] += 1


    cursor.close()
    conn.close()


# ==========================================
# RUN PESSIMISTIC TEST
# ==========================================

def run_pessimistic():

    threads = []

    start_time = time.time()

    for i in range(NUM_THREADS):

        t = threading.Thread(
            target=pessimistic_worker,
            args=(i,)
        )

        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    return round(time.time() - start_time, 2)


# ==========================================
# RUN OPTIMISTIC TEST
# ==========================================

def run_optimistic():

    threads = []

    start_time = time.time()

    for i in range(NUM_THREADS):

        t = threading.Thread(
            target=optimistic_worker,
            args=(i,)
        )

        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    return round(time.time() - start_time, 2)


# ==========================================
# READ MYSQL LOG COUNTS
# ==========================================

def get_db_metrics():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT COUNT(*)
        FROM conflict_log
    """)
    conflict_count = cursor.fetchone()[0]

    cursor.execute("""
        SELECT COUNT(*)
        FROM deadlock_log
    """)
    deadlock_count = cursor.fetchone()[0]

    cursor.execute("""
        SELECT COUNT(*)
        FROM transaction_log
    """)
    transaction_count = cursor.fetchone()[0]

    cursor.close()
    conn.close()

    return (
        conflict_count,
        deadlock_count,
        transaction_count
    )


# ==========================================
# MAIN
# ==========================================

if __name__ == "__main__":

    print("\nResetting environment...\n")

    reset_test_environment()

    print("Running pessimistic test...\n")

    pess_time = run_pessimistic()

    print("Running optimistic test...\n")

    opt_time = run_optimistic()

    conflict_count, deadlock_count, transaction_count = get_db_metrics()

    print("\n")
    print("=" * 85)
    print("CONCURRENCY TEST RESULTS")
    print("=" * 85)

    print(
        f"{'Metric':<25}"
        f"{'Pessimistic':<20}"
        f"{'Optimistic':<20}"
    )

    print("-" * 85)

    print(
        f"{'Runtime (seconds)':<25}"
        f"{pess_time:<20}"
        f"{opt_time:<20}"
    )

    print(
        f"{'Success Count':<25}"
        f"{metrics['pessimistic']['success']:<20}"
        f"{metrics['optimistic']['success']:<20}"
    )

    print(
        f"{'Exception Count':<25}"
        f"{metrics['pessimistic']['errors']:<20}"
        f"{metrics['optimistic']['errors']:<20}"
    )

    print(
        f"{'Deadlocks (1213)':<25}"
        f"{metrics['pessimistic']['deadlocks']:<20}"
        f"{metrics['optimistic']['deadlocks']:<20}"
    )

    print(
        f"{'Timeouts (1205)':<25}"
        f"{metrics['pessimistic']['timeouts']:<20}"
        f"{metrics['optimistic']['timeouts']:<20}"
    )

    print("-" * 85)

    print(
        f"{'Conflict Log Rows':<25}"
        f"{'-':<20}"
        f"{conflict_count:<20}"
    )

    print(
        f"{'Deadlock Log Rows':<25}"
        f"{deadlock_count:<20}"
        f"{'-':<20}"
    )

    print(
        f"{'Transaction Log Rows':<25}"
        f"{transaction_count:<20}"
        f"{transaction_count:<20}"
    )

    print("=" * 85)