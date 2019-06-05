#!/bin/bash

BEFORE="$1"
AFTER="$2"
BINARIES=( "${BEFORE}" "${AFTER}" )
OUTPUT=benchmark-$(date +%Y%m%d-%H%M%S)
mkdir -p $OUTPUT

roachprod stop ${CLUSTER}
for b in ${BINARIES[@]}; do
 roachprod put ${CLUSTER}:1-4 $b
done

roachprod stage ${CLUSTER}:4 workload
N=5
DURATION=5m
READ_PERCENT=99
CONCURRENCY=128
for i in $(seq 1 $N); do
  for b in ${BINARIES[@]}; do
    echo $b $i
    roachprod stop ${CLUSTER}:1-3
    roachprod wipe ${CLUSTER}:1-3
    roachprod start ${CLUSTER}:1-3 --binary $b
    sleep 1
    roachprod run ${CLUSTER}:4 -- \
              ./workload run kv {pgurl:1-3} --init \
              --duration ${DURATION} \
              --ramp 10s \
              --splits 32 \
              --read-percent=${READ_PERCENT} \
              --concurrency=${CONCURRENCY} | tee ${OUTPUT}/bench-$(basename $b).$i.txt
  done
done

make_bench() {
  b=$(basename $1)
  awk '
  { printf("BenchmarkKV'"${READ_PERCENT}"'-throughput\t1\t%f ops/s\n", $4); }
  { printf("BenchmarkKV'"${READ_PERCENT}"'-P50\t1\t%f ms/s\n", $7); }
  { printf("BenchmarkKV'"${READ_PERCENT}"'-Avg\t1\t%f ms/s\n", $6); }
' <( tail -q -n1 ${OUTPUT}/bench-$(basename $b)* )
}

benchstat <(make_bench $BEFORE) <(make_bench $AFTER) | tee ${OUTPUT}/results.txt
