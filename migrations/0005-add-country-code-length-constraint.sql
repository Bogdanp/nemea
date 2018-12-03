alter table page_visits add constraint country_code_length check(length(country_code) = 2)
