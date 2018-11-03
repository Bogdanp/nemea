create table page_visits (
  date date not null,
  host text not null,
  path text not null,
  referrer_host text not null,
  referrer_path text not null,

  visits bigint not null,
  visitors hll not null default hll_empty(),
  sessions hll not null default hll_empty(),

  unique(date, host, path, referrer_host, referrer_path)
);
