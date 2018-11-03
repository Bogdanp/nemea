import addDays from "date-fns/add_days";
import compareAsc from "date-fns/compare_asc";
import format from "date-fns/format";
import startOfDay from "date-fns/start_of_day";

export function formatDate(date) {
  return format(date, "YYYY-MM-DD");
}

export function datesInRange(lo, hi) {
  let range = [];
  let current = lo;
  while (compareAsc(current, hi) < 0) {
    range.push(current);
    current = addDays(current, 1);
  }

  return range;
}

export function makeContinuous(lo, hi, timeseries) {
  const range = datesInRange(lo, hi);
  const countsByDate = timeseries.reduce((acc, { date, value }) => {
    acc[startOfDay(date)] = value;
    return acc;
  }, {});

  return range.map(date => [date, countsByDate[date] || 0]);
}
