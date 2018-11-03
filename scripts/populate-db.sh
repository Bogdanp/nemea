#!/usr/bin/env bash

set -euo pipefail

referrer_hosts=("" "google.com" "yahoo.com" "producthunt.com" "reddit.com")
referrer_paths=("" "/search" "/" "/posts/nemea" "/r/analytics")

scale=1

echo 'truncate page_visits' | psql -Unemea -dnemea
for p in "/" "/login" "/signup" "/data" "/pricing" "/privacy" "/terms"
do
    scale=$((scale * 3))

    for i in "${!referrer_hosts[@]}"
    do
        host=${referrer_hosts[$i]}
        path=${referrer_paths[$i]}
        psql -Unemea -dnemea <<EOF
with
  range as (select date_trunc('day', d) as d from generate_series(now() - '365 days'::interval, now(), '1 day'::interval) d)
insert into
  page_visits(date, host, path, referrer_host, referrer_path, visits)
select
  r.d as date,
  'example.com' as host,
  '$p' as path,
  '$host' as referrer_host,
  '$path' as referrer_path,
  (300 + random() * 100000) / $scale as visits
from range r
EOF
    done
done

for i in $(seq 0 365)
do
    date=$(date -v-"${i}d" +%Y-%m-%d)
    psql -Unemea -dnemea <<EOF
with
  sessions as (select hll_add_agg(hll_hash_integer(x)) as s from generate_series(1, (300 + random() * 1500)::int) x),
  visitors as (select hll_add_agg(hll_hash_integer(x)) as v from generate_series(1, (200 + random() * 500)::int) x)
update page_visits
set
  sessions = sessions || (select s from sessions),
  visitors = visitors || (select v from visitors)
where
  date = '$date'
EOF
done
