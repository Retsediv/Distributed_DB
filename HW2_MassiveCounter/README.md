## Hazelcast setup

1. Run hazelcast

```(bash)
docker compose up
```

2. Check out Management Center to see if everything works (go to localhost:8080 and enable dev mode).

## Results

```
[PART 1 | NON-Blocking Map]
Execution time: 22.826687812805176
final counter value: 10007
=== FINISHED ===

[PART 2 | Pessimistic Blocking]
Execution time: 302.0588409900665
final counter value: 100000
=== FINISHED ===

[PART 3 | Optimistic Blocking]
Execution time: 1105.5332098007202
final counter value: 100000
=== FINISHED ===

[PART 4 | Atomic]
final counter value: 100000
Execution time: 30.487966060638428
=== FINISHED ===



```
