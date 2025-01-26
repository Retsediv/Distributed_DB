import threading
import time
from enum import Enum
from threading import Thread
from typing import Callable

import hazelcast

WRITES = 10_000
NUM_OF_THREADS = 10
KEY = "counter"


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


@timer
def run_experiment(fn: Callable) -> int:
    client = hazelcast.HazelcastClient(cluster_name="dev")
    atomic = client.cp_subsystem.get_atomic_long(KEY)
    atomic.set(0).result()

    threads = [Thread(target=fn) for _ in range(NUM_OF_THREADS)]
    for thread in threads:
        thread.start()

    for thread in threads:
        thread.join()

    final_value = atomic.get().result()
    print(f"final counter value: {final_value}")
    client.shutdown()

    return final_value


def atomic_increment():
    print(f"Thread {threading.current_thread().ident} started")

    client = hazelcast.HazelcastClient(cluster_name="dev")
    atomic = client.cp_subsystem.get_atomic_long(KEY)

    for i in range(0, WRITES):
        atomic.increment_and_get().result()

        if i % 500 == 0:
            print(f"progress | i: {i} | ....")


def main():
    print("\n[PART 4 | Atomic]")
    result = run_experiment(atomic_increment)
    print(f"final counter value: {result}")
    print("=== FINISHED ===")


if __name__ == "__main__":
    main()
