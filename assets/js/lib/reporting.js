import format from "date-fns/format";
import startOfDay from "date-fns/start_of_day";
import startOfTomorrow from "date-fns/start_of_tomorrow";

import request from "./client.js";

function formatDate(date) {
  return format(date, "YYYY-MM-DD");
}

export function getDailyReport(startDate, endDate) {
  startDate = startDate || startOfDay(new Date());
  endDate = endDate || startOfTomorrow();

  return request("/v0/reports/daily", {
    params: {
      lo: formatDate(startDate),
      hi: formatDate(endDate)
    }
  });
}
