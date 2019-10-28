import startOfDay from "date-fns/start_of_day";
import startOfTomorrow from "date-fns/start_of_tomorrow";

import { formatDate } from "./dates.js";
import request from "./client.js";

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

export const visitorTracker = {
  _tracker: null,
  _listeners: [],

  addListener(event, listener) {
    if (!this._tracker) {
      this._tracker = initCurrentVisitorsTracker(this.dispatch.bind(this));
    }

    this._listeners.push([event, listener]);
  },

  removeListener(event, listener) {
    this._listeners.splice(this._listeners.indexOf([event, listener]), 1);
  },

  dispatch(event, data) {
    this._listeners.forEach(([e, f]) => {
      if (e === event) {
        f(data);
      }
    });
  }
};

function initCurrentVisitorsTracker(dispatch) {
  const source = new EventSource("/v0/visitors-stream", {
    withCredentials: true
  });

  source.addEventListener("count", e => {
    dispatch("count", Number(e.data));
  });

  source.addEventListener("locations", e => {
    dispatch("locations", JSON.parse(e.data));
  });

  return source;
}
