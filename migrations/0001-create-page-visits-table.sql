create table page_visits (
  date date not null,
  path text not null,
  referrer_host text not null,
  referrer_path text not null,
  country text not null,
  os text not null,
  browser text not null,

  visits bigint not null,

  unique(date, path, referrer_host, referrer_path, country, os, browser)
);
