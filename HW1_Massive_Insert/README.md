# Massive Insert

Investigating:

- Lost-update (naive select and then update)
- In-place update
- Row-level locking
- Optimistic concurrency control


## Results

```(text)

[Creating a table]
Table already exists
Counter value: 0

[Lost update]
Execution time: 60.2471182346344
Counter value: 11235

[Lost update | SERIALIZABLE]
Execution time: 59.73392295837402
Counter value: 11158

[IN-PLACE UPDATE]
Execution time: 58.58991003036499
Counter value: 100000

[ROW-LEVEL LOCKING]
Execution time: 77.62678718566895
Counter value: 100000

[OPTIMISTIC CONCURRENCY CONTROL]
Execution time: veeeeeery long
Counter value: 100000
```
