Run Cassanda using docker:

```(bash)
docker network create cassndra-network
docker run --name my-cassandra --network cassndra-network -d cassandra:5.0
```
