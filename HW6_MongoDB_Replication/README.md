# Homework 6 - MongoDB Replication

## Commands log

1. Deploy a replica set with 3 nodes
```bash
docker network create mongo-net

docker run -d --name mongo1 --network mongo-net -p 27017:27017 mongo:8.0 --replSet rs0 --bind_ip localhost,mongo1
docker run -d --name mongo2 --network mongo-net -p 27018:27017 mongo:8.0 --replSet rs0 --bind_ip localhost,mongo2
docker run -d --name mongo3 --network mongo-net -p 27019:27017 mongo:8.0 --replSet rs0 --bind_ip localhost,mongo3
```

Initiate the replica set

```bash
brew install mongosh
mongosh --port 27017

rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017" },
    { _id: 1, host: "mongo2:27017" },
    { _id: 2, host: "mongo3:27017" }
  ]
});

rs.conf()
```

The output:
```bash
test> rs.initiate({
...   _id: "rs0",
...   members: [
...     { _id: 0, host: "mongo1:27017" },
...     { _id: 1, host: "mongo2:27017" },
...     { _id: 2, host: "mongo3:27017" }
...   ]
... });
...
...
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1741033961, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1741033961, i: 1 })
}
rs0 [direct: secondary] test> rs.conf()
...
{
  _id: 'rs0',
  version: 1,
  term: 0,
  members: [
    {
      _id: 0,
      host: 'mongo1:27017',
      arbiterOnly: false,
      buildIndexes: true,
      hidden: false,
      priority: 1,
      tags: {},
      secondaryDelaySecs: Long('0'),
      votes: 1
    },
    {
      _id: 1,
      host: 'mongo2:27017',
      arbiterOnly: false,
      buildIndexes: true,
      hidden: false,
      priority: 1,
      tags: {},
      secondaryDelaySecs: Long('0'),
      votes: 1
    },
    {
      _id: 2,
      host: 'mongo3:27017',
      arbiterOnly: false,
      buildIndexes: true,
      hidden: false,
      priority: 1,
      tags: {},
      secondaryDelaySecs: Long('0'),
      votes: 1
    }
  ],
  protocolVersion: Long('1'),
  writeConcernMajorityJournalDefault: true,
  settings: {
    chainingAllowed: true,
    heartbeatIntervalMillis: 2000,
    heartbeatTimeoutSecs: 10,
    electionTimeoutMillis: 10000,
    catchUpTimeoutMillis: -1,
    catchUpTakeoverDelayMillis: 30000,
    getLastErrorModes: {},
    getLastErrorDefaults: { w: 1, wtimeout: 0 },
    replicaSetId: ObjectId('67c611e9fc9b6282e354600d')
  }
}
```
2. Demonstrate Read Preference Modes: read from primary and secondary node

```bash
# Insert sample data
mongosh --port 27017

rs0 [direct: secondary] test> db.products.insertMany([
...   { name: "Laptop", price: 999 },
...   { name: "Phone", price: 699 }
... ])
...
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('67c6a60d9dfea873bca43382'),
    '1': ObjectId('67c6a60d9dfea873bca43383')
  }
}


# Read from Primary
rs0 [direct: primary] test> db.products.find().readPref("primary")
...
[
  {
    _id: ObjectId('67c6a60d9dfea873bca43382'),
    name: 'Laptop',
    price: 999
  },
  {
    _id: ObjectId('67c6a60d9dfea873bca43383'),
    name: 'Phone',
    price: 699
  }
]

```

```bash
# Read from Secondary
rs0 [direct: secondary] test> rs.secondaryOk()
...
DeprecationWarning: .setSecondaryOk() is deprecated. Use .setReadPref("primaryPreferred") instead
Setting read preference from "primary" to "primaryPreferred"

rs0 [direct: secondary] test> db.products.find().readPref("secondary")
...
[
  {
    _id: ObjectId('67c6a60d9dfea873bca43382'),
    name: 'Laptop',
    price: 999
  },
  {
    _id: ObjectId('67c6a60d9dfea873bca43383'),
    name: 'Phone',
    price: 699
  }
]

```

3. Make a write with 1 disconnected node and wrice concern 3. Try to turn on the disconnected node during timeout

```bash
# Disconnect the node (on another node)
docker stop mongo3

# Write with write concern 3
db.collection.insert(
   { data: "test" },
   { writeConcern: { w: 3, wtimeout: 0 } }
);


# Connect back the node
docker start mongo3

# Now the output on the "write node":
db.collection.insert(
   { data: "test" },
   { writeConcern: { w: 3, wtimeout: 0 } }
 );
```

Log:
```
rs0 [direct: primary] test> db.collection.insert(
...   { data: "test" },
...   { writeConcern: { w: 3, wtimeout: 0 } }
... );
...
DeprecationWarning: Collection.insert() is deprecated. Use insertOne, insertMany, or bulkWrite.
^[{
  acknowledged: true,
  insertedIds: { '0': ObjectId('67c6a72e9dfea873bca43384') }
}
rs0 [direct: primary] test>

```

4. Use a finite timeout and wait for it to end. Check if data is written and available for reading with readConcern level: "majority"

```bash

# Stop the node
docker stop mongo3

# Write data
db.collection.insert(
  { data: "timeout-test-finite" },
  { writeConcern: { w: 3, wtimeout: 5000 } }
);

db.collection.find().readConcern("majority")
```

Log:
```
rs0 [direct: primary] test> db.collection.insert(
...   { data: "timeout-test-finite" },
...   { writeConcern: { w: 3, wtimeout: 5000 } }
... );
...
Uncaught:
MongoBulkWriteError: waiting for replication timed out
Result: BulkWriteResult {
  insertedCount: 1,
  matchedCount: 0,
  modifiedCount: 0,
  deletedCount: 0,
  upsertedCount: 0,
  upsertedIds: {},
  insertedIds: { '0': ObjectId('67c6a8549dfea873bca43386') }
}
Write Errors: []
rs0 [direct: primary] test>

rs0 [direct: primary] test> db.collection.find().readConcern("majority")
...
[
  { _id: ObjectId('67c6a72e9dfea873bca43384'), data: 'test' },
  { _id: ObjectId('67c6a8249dfea873bca43385'), data: 'timeout-test' },
  {
    _id: ObjectId('67c6a8549dfea873bca43386'),
    data: 'timeout-test-finite'
  }
]

```


5. Demonstrate re-election of ~~Trump~~ primary node by stopping the current primary noda


```bash
# Stop the primary node
docker stop mongo1

# Check new primary ()
rs.status()

# Add new data (on new PRIMARY)
db.products.insertOne({ name: "NEW_DATA", price: 999999 })

# Check if data is available (on new PRIMARY and old PRIMARY)
db.products.find()
```

Log:
```
rs0 [direct: primary] test> rs.status()
{
  set: 'rs0',
  date: ISODate('2025-03-04T07:20:38.339Z'),
  myState: 1,
  term: Long('2'),
  syncSourceHost: '',
  syncSourceId: -1,
  heartbeatIntervalMillis: Long('2000'),
  majorityVoteCount: 2,
  writeMajorityCount: 2,
  votingMembersCount: 3,
  writableVotingMembersCount: 3,
  optimes: {
    lastCommittedOpTime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
    lastCommittedWallTime: ISODate('2025-03-04T07:20:34.400Z'),
    readConcernMajorityOpTime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
    appliedOpTime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
    durableOpTime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
    writtenOpTime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
    lastAppliedWallTime: ISODate('2025-03-04T07:20:34.400Z'),
    lastDurableWallTime: ISODate('2025-03-04T07:20:34.400Z'),
    lastWrittenWallTime: ISODate('2025-03-04T07:20:34.400Z')
  },
  lastStableRecoveryTimestamp: Timestamp({ t: 1741072794, i: 2 }),
  electionCandidateMetrics: {
    lastElectionReason: 'stepUpRequestSkipDryRun',
    lastElectionDate: ISODate('2025-03-04T07:19:54.389Z'),
    electionTerm: Long('2'),
    lastCommittedOpTimeAtElection: { ts: Timestamp({ t: 1741072791, i: 1 }), t: Long('1') },
    lastSeenWrittenOpTimeAtElection: { ts: Timestamp({ t: 1741072791, i: 1 }), t: Long('1') },
    lastSeenOpTimeAtElection: { ts: Timestamp({ t: 1741072791, i: 1 }), t: Long('1') },
    numVotesNeeded: 2,
    priorityAtElection: 1,
    electionTimeoutMillis: Long('10000'),
    priorPrimaryMemberId: 0,
    numCatchUpOps: Long('0'),
    newTermStartDate: ISODate('2025-03-04T07:19:54.394Z'),
    wMajorityWriteAvailabilityDate: ISODate('2025-03-04T07:19:54.399Z')
  },
  electionParticipantMetrics: {
    votedForCandidate: true,
    electionTerm: Long('1'),
    lastVoteDate: ISODate('2025-03-04T07:04:00.990Z'),
    electionCandidateMemberId: 0,
    voteReason: '',
    lastWrittenOpTimeAtElection: { ts: Timestamp({ t: 1741071830, i: 1 }), t: Long('-1') },
    maxWrittenOpTimeInSet: { ts: Timestamp({ t: 1741071830, i: 1 }), t: Long('-1') },
    lastAppliedOpTimeAtElection: { ts: Timestamp({ t: 1741071830, i: 1 }), t: Long('-1') },
    maxAppliedOpTimeInSet: { ts: Timestamp({ t: 1741071830, i: 1 }), t: Long('-1') },
    priorityAtElection: 1
  },
  members: [
    {
      _id: 0,
      name: 'mongo1:27017',
      health: 0,
      state: 8,
      stateStr: '(not reachable/healthy)',
      uptime: 0,
      optime: { ts: Timestamp({ t: 0, i: 0 }), t: Long('-1') },
      optimeDurable: { ts: Timestamp({ t: 0, i: 0 }), t: Long('-1') },
      optimeWritten: { ts: Timestamp({ t: 0, i: 0 }), t: Long('-1') },
      optimeDate: ISODate('1970-01-01T00:00:00.000Z'),
      optimeDurableDate: ISODate('1970-01-01T00:00:00.000Z'),
      optimeWrittenDate: ISODate('1970-01-01T00:00:00.000Z'),
      lastAppliedWallTime: ISODate('2025-03-04T07:19:54.394Z'),
      lastDurableWallTime: ISODate('2025-03-04T07:19:54.394Z'),
      lastWrittenWallTime: ISODate('2025-03-04T07:20:04.396Z'),
      lastHeartbeat: ISODate('2025-03-04T07:20:36.666Z'),
      lastHeartbeatRecv: ISODate('2025-03-04T07:20:02.914Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: 'Error connecting to mongo1:27017 :: caused by :: Could not find address for mongo1:27017: SocketException: onInvoke :: caused by :: Host not found (authoritative)',
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      configVersion: 1,
      configTerm: 2
    },
    {
      _id: 1,
      name: 'mongo2:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      uptime: 1035,
      optime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
      optimeDate: ISODate('2025-03-04T07:20:34.000Z'),
      optimeWritten: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
      optimeWrittenDate: ISODate('2025-03-04T07:20:34.000Z'),
      lastAppliedWallTime: ISODate('2025-03-04T07:20:34.400Z'),
      lastDurableWallTime: ISODate('2025-03-04T07:20:34.400Z'),
      lastWrittenWallTime: ISODate('2025-03-04T07:20:34.400Z'),
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      electionTime: Timestamp({ t: 1741072794, i: 1 }),
      electionDate: ISODate('2025-03-04T07:19:54.000Z'),
      configVersion: 1,
      configTerm: 2,
      self: true,
      lastHeartbeatMessage: ''
    },
    {
      _id: 2,
      name: 'mongo3:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 52,
      optime: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
      optimeDurable: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
      optimeWritten: { ts: Timestamp({ t: 1741072834, i: 1 }), t: Long('2') },
      optimeDate: ISODate('2025-03-04T07:20:34.000Z'),
      optimeDurableDate: ISODate('2025-03-04T07:20:34.000Z'),
      optimeWrittenDate: ISODate('2025-03-04T07:20:34.000Z'),
      lastAppliedWallTime: ISODate('2025-03-04T07:20:34.400Z'),
      lastDurableWallTime: ISODate('2025-03-04T07:20:34.400Z'),
      lastWrittenWallTime: ISODate('2025-03-04T07:20:34.400Z'),
      lastHeartbeat: ISODate('2025-03-04T07:20:36.426Z'),
      lastHeartbeatRecv: ISODate('2025-03-04T07:20:36.426Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: '',
      syncSourceHost: 'mongo2:27017',
      syncSourceId: 1,
      infoMessage: '',
      configVersion: 1,
      configTerm: 2
    }
  ],
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1741072834, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1741072834, i: 1 })
}
rs0 [direct: primary] test>


```

6. Put cluster into inconsistent state

```bash
# Stop two secondary
docker stop mongo1 mongo3

# Write data from Primary with write_concern 1 (within 5 second after shutting down secondaries!!!)
db.collection.insert({ data: "inconsistent_DATA" }, { writeConcern: { w: 1 } });

# Read data using different read concerns
# local: data is available
# majority/linearizable: data is absent
db.collection.find().readConcern("local")
db.collection.find().readConcern("majority")
db.collection.find().readConcern("linearizable")

# Run mongo1, mongo2, but isolate mongo2
docker network disconnect mongo-net mongo2

# When new primary is elected, the data will be absent
db.collection.find().readConcern("majority")
```

Log:

```
db.collection.insert({ data: "inconsistent_DATA" }, { writeConcern: { w: 1 } });
...
{
  acknowledged: true,
  insertedIds: { '0': ObjectId('67c6ae6ff3d345d1ea3ec477') }

rs0 [direct: primary] test> db.collection.find().readConcern("local")
[
  { _id: ObjectId('67c6a72e9dfea873bca43384'), data: 'test' },
  { _id: ObjectId('67c6a8249dfea873bca43385'), data: 'timeout-test' },
  {
    _id: ObjectId('67c6a8549dfea873bca43386'),
    data: 'timeout-test-finite'
  },
  {
    _id: ObjectId('67c6ae6ff3d345d1ea3ec477'),
    data: 'inconsistent_DATA'
  }
]
rs0 [direct: secondary] test> db.collection.find().readConcern("majority")
[
  { _id: ObjectId('67c6a72e9dfea873bca43384'), data: 'test' },
  { _id: ObjectId('67c6a8249dfea873bca43385'), data: 'timeout-test' },
  {
    _id: ObjectId('67c6a8549dfea873bca43386'),
    data: 'timeout-test-finite'
  }
]
rs0 [direct: secondary] test> db.collection.find().readConcern("linearizable")
MongoServerError[NotWritablePrimary]: cannot satisfy linearizable read concern on non-primary node
```


7. Emulate eventual consistency using an artificial delay

```bash
cfg = rs.conf();
cfg.members[2].priority = 0;
cfg.members[2].hidden = true;
cfg.members[2].slaveDelay = 3600; // Затримка 1 година
rs.reconfig(cfg);

# Write on primary
db.collection.insert({ data: "eventual-consistency" });

# Check data on node2
db.collection.find()
```

8. Check linearizability

```bash
# Stop secondary
docker stop mongo1

# Write data
db.collection.insert({ data: "linear-test1" });
db.collection.insert({ data: "linear-test2" });
db.collection.insert({ data: "linear-test3" });

# Try to read
db.collection.find().readConcern("linearizable")
```
