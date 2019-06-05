Make sure you have benchstat and roachprod in your PATH

1) Create a directory for data
1) Create a cluster with roachprod
1) cd into the directory
1) copy two versions of cockroach into the directory
1) Run the test

```
CLUSTER=... ../test_kv99.sh cockroach-base cockroach-with-change
```
