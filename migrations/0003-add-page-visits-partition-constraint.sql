alter table page_visits add constraint page_visits_partition unique(date, host, path, referrer_host, referrer_path, country_code);
