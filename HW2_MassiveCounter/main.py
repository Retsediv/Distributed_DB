import threading
import time
from enum import Enum
from threading import Thread
from typing import Callable

import hazelcast

WRITES = 10_000
NUM_OF_THREADS = 10
MAP_NAME = "map"
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


class LockType(Enum):
    NON_BLOCKING = 1
    PESSIMISTIC_BLOCKING = 2
    OPTIMISTIC_BLOCKING = 3


@timer
def run_experiment(fn: Callable, lock_type: LockType) -> int:
    threads = [Thread(target=fn, args=(lock_type,)) for _ in range(NUM_OF_THREADS)]
    for thread in threads:
        thread.start()

    for thread in threads:
        thread.join()

    # global stuff just to make everything simple
    client = hazelcast.HazelcastClient(cluster_name="dev")

    map = client.get_map(MAP_NAME).blocking()
    final_value = map.get(KEY)
    print(f"final counter value: {final_value}")
    client.shutdown()

    return final_value


def map_increment(lock_type: LockType):
    print(f"Thread {threading.current_thread().ident} started")

    client = hazelcast.HazelcastClient(cluster_name="dev")
    if lock_type == LockType.NON_BLOCKING:
        m = client.get_map(MAP_NAME)
    else:
        m = client.get_map(MAP_NAME).blocking()

    m.put(KEY, 0)

    if lock_type == LockType.PESSIMISTIC_BLOCKING:
        m.force_unlock(KEY)

    for i in range(0, WRITES):
        if lock_type == LockType.NON_BLOCKING:
            counter = m.get(KEY).result()
            m.set(KEY, counter + 1)
        elif lock_type == LockType.PESSIMISTIC_BLOCKING:
            m.lock(KEY)
            try:
                counter = m.get(KEY)
                print(f"current counter: {counter}")
                m.set(KEY, counter + 1)
            except Exception as _:
                pass
            finally:
                m.unlock(KEY)

        elif lock_type == LockType.OPTIMISTIC_BLOCKING:
            while True:
                counter = m.get(KEY)
                if m.replace_if_same(KEY, counter, counter + 1):
                    break
            print(f"current counter: {counter}")

        if i % 500 == 0:
            print(f"progress | counter: {counter}")


def main():
    print("\n[PART 1 | NON-Blocking Map]")
    result = run_experiment(map_increment, LockType.NON_BLOCKING)
    print(f"final counter value: {result}")
    print("=== FINISHED ===")

    print("\n[PART 2 | Pessimistic Blocking]")
    result = run_experiment(map_increment, LockType.PESSIMISTIC_BLOCKING)
    print(f"final counter value: {result}")
    print("=== FINISHED ===")

    print("\n[PART 3 | Optimistic Blocking]")
    result = run_experiment(map_increment, LockType.OPTIMISTIC_BLOCKING)
    print(f"final counter value: {result}")
    print("=== FINISHED ===")


if __name__ == "__main__":
    main()
