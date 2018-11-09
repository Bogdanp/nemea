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

  addListener(onUpdate) {
    if (!this._tracker) {
      this._tracker = initCurrentVisitorsTracker(this.dispatch.bind(this));
    }

    this._listeners.push(onUpdate);
  },

  removeListener(onUpdate) {
    this._listeners.splice(this._listeners.indexOf(onUpdate), 1);
  },

  dispatch(visitors) {
    this._listeners.forEach(f => f(visitors));
  }
};

function initCurrentVisitorsTracker(onUpdate) {
  return fetch("/v0/visitors-stream", {
    credentials: "same-origin"
  })
    .then(stream)
    .then(restart);

  function stream(response) {
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    return readChunk();

    function readChunk() {
      return reader.read().then(chunk => {
        if (chunk.done) {
          return;
        }

        const data = decoder.decode(chunk.value || new Uint8Array(), {
          stream: !chunk.done
        });

        onUpdate(data * 1);
        return readChunk();
      });
    }
  }

  function restart() {
    return initCurrentVisitorsTracker(onUpdate);
  }
}
