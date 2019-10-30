<template>
  <div class="container">
    <div class="totals">
      <totals-box id="visits" label="Visits"
                  :value="report.totals.visits"
                  :active="currentReport == 'visits'"
                  @activate="reportChanged"></totals-box>

      <totals-box id="sessions" label="Sessions"
                  :value="report.totals.sessions"
                  :active="currentReport == 'sessions'"
                  @activate="reportChanged"></totals-box>

      <totals-box id="visitors" label="Visitors"
                  :value="report.totals.visitors"
                  :active="currentReport == 'visitors'"
                  @activate="reportChanged"></totals-box>

      <totals-box id="online" label="Online"
                  :value="onlineVisiors"
                  :active="currentReport == 'online'"
                  @activate="reportChanged"></totals-box>
    </div>

    <div class="charts">
      <card :no-padding="true">
        <template slot="header">
          <select :value="preset" @change="rangeChanged">
            <option value="today">Today</option>
            <option value="yesterday">Yesterday</option>
            <option value="last-7">Last 7 Days</option>
            <option value="last-14">Last 14 Days</option>
            <option value="last-30">Last 30 Days</option>
            <option value="last-90">Last 90 Days</option>
            <option value="this-year">This Year</option>
          </select>
        </template>

        <chart v-if="chartVisible" :type="chartType" :height="chartHeight" :options="chartOptions" :series="series"></chart>
      </card>
    </div>

    <div class="reports reports--wide">
      <live-locations :locations="liveLocations"></live-locations>
    </div>

    <div class="reports">
      <top-pages :breakdown="report['pages-breakdown']"></top-pages>
      <top-referrers :breakdown="report['referrers-breakdown']"></top-referrers>
    </div>
  </div>
</template>

<script>
  import { arraysEqual } from "../lib/arrays.js";
  import { datesInRange, formatDate, makeContinuous } from "../lib/dates.js";
  import { numeric } from "../lib/formatting.js";
  import { getDailyReport, visitorTracker } from "../lib/reporting.js";
  import { makeTimeseriesOptions } from "../lib/charts.js";

  import Card from "../components/Card.vue";
  import LiveLocations from "../components/LiveLocations.vue";

  import TopPages from "../components/TopPages.vue";
  import TopReferrers from "../components/TopReferrers.vue";
  import TotalsBox from "../components/TotalsBox.vue";

  import VueApexCharts from "vue-apexcharts";
  import addDays from "date-fns/add_days";
  import differenceInDays from "date-fns/difference_in_days";
  import distanceInWords from "date-fns/distance_in_words";
  import subDays from "date-fns/sub_days";
  import startOfDay from "date-fns/start_of_day";
  import startOfTomorrow from "date-fns/start_of_tomorrow";
  import startOfToday from "date-fns/start_of_today";
  import startOfYesterday from "date-fns/start_of_today";

  const MAX_ONLINE_TIMESERIES_LENGTH = 10;

  const BAR_CHART_CUTOFF = 14;

  const DATE_PRESETS = {
    "today": () => [startOfToday(), startOfTomorrow()],
    "yesterday": () => [subDays(startOfToday(), 1), startOfToday()],
    "last-7": () => [subDays(startOfToday(), 6), startOfTomorrow()],
    "last-14": () => [subDays(startOfToday(), 13), startOfTomorrow()],
    "last-30": () => [subDays(startOfToday(), 29), startOfTomorrow()],
    "last-90": () => [subDays(startOfToday(), 89), startOfTomorrow()],
    "this-year": () => [subDays(startOfToday(), 364), startOfTomorrow()],
  };

  export default {
    name: "Dashboard",
    components: {
      Card,
      LiveLocations,
      TopPages,
      TopReferrers,
      TotalsBox,

      chart: VueApexCharts,
    },

    data() {
      const now = new Date() * 1;
      const onlineVisitorsByMinute = {};
      for (let i = 0; i < MAX_ONLINE_TIMESERIES_LENGTH; i++) {
        onlineVisitorsByMinute[now - now % 60000 - i * 60000] = 0;
      }

      return {
        currentReport: "visits",
        preset: "last-7",
        report: {
          totals: {
            visits: 0,
            sessions: 0,
            visitors: 0,
            "avg-time": 0,
          },
          timeseries: [[], []],
          ["pages-breakdown"]: [],
          ["referrers-breakdown"]: [],
        },

        liveLocations: [],
        onlineVisiors: 0,
        onlineVisitorsByMinute: onlineVisitorsByMinute,
        onlineVisitorsTimeseries: [],
      };
    },

    created() {
      getDailyReport(this.startDate, this.endDate)
        .then(report => {
          this.report = report;
        });

      this._visitorCountChanged = this.visitorCountChanged.bind(this);
      this._visitorLocationsChanged = this.visitorLocationsChanged.bind(this);
      visitorTracker.addListener("count", this._visitorCountChanged);
      visitorTracker.addListener("locations", this._visitorLocationsChanged);
    },

    beforeDestroy() {
      visitorTracker.removeListener("count", this._visitorCountChanged);
      visitorTracker.removeListener("locations", this._visitorLocationsChanged);
    },

    computed: {
      dateRange() {
        return DATE_PRESETS[this.preset]();
      },

      startDate() {
        return this.dateRange[0];
      },

      endDate() {
        return this.dateRange[1];
      },

      daysInRange() {
        return differenceInDays(this.endDate, this.startDate);
      },

      chartHeight() {
        return window.innerWidth < 720 ? 220 : 300;
      },

      chartOptions() {
        const options = makeTimeseriesOptions();
        options.chart.sparkline = { enabled: true };
        options.grid.padding.top = 0;
        options.grid.padding.left = 0;
        options.grid.padding.right = 0;

        if (this.chartType === "bar") {
          options.fill.opacity = 1;
          options.tooltip = {
            x: {
              formatter: formatDate,
            },
            y: {
              formatter: numeric,
            },
          };
        } else if (this.currentReport === "online") {
          options.fill.opacity = [0.2, 0];
          options.tooltip = {
            x: {
              formatter: (date) => {
                return distanceInWords(new Date, date, { addSuffix: true });
              },
            },
            y: {
              formatter: numeric,
            },
          };
        } else {
          options.fill.opacity = [0.2, 0];
          options.tooltip = {
            x: {
              formatter: (date) => {
                return `${formatDate(date)} vs ${formatDate(subDays(date, this.daysInRange))}`;
              },
            },
            y: {
              formatter: numeric,
            },
          };
        }

        return options;
      },

      chartType() {
        return this.daysInRange > BAR_CHART_CUTOFF ? "bar" : "area";
      },

      chartVisible() {
        return this.daysInRange > 1;
      },

      series() {
        if (this.currentReport === "online") {
          return [{
            name: "online",
            data: this.onlineVisitorsTimeseries,
          }];
        }

        const currentTimeseries = makeContinuous(
          this.startDate,
          this.endDate,
          this.report.timeseries[1].map(data => ({
            date: new Date(data.date),
            value: data[this.currentReport],
          }))
        );

        if (this.chartType === "bar") {
          return [{
            name: this.currentReport,
            data: currentTimeseries,
          }];
        }

        const previousTimeseries = makeContinuous(
          this.startDate,
          this.endDate,
          this.report.timeseries[0].map(data => ({
            date: addDays(new Date(data.date), this.daysInRange),
            value: data[this.currentReport],
          }))
        );

        return [{
          name: this.currentReport,
          data: currentTimeseries,
        }, {
          name: "previously",
          data: previousTimeseries,
        }];
      },
    },

    methods: {
      rangeChanged(e) {
        const preset = e.target.value;
        const [lo, hi] = DATE_PRESETS[preset]();

        getDailyReport(lo, hi)
          .then(report => {
            this.preset = preset;
            this.report = report;
          });
      },

      reportChanged(id) {
        this.currentReport = id;
      },

      visitorCountChanged(visitors) {
        const now = new Date() * 1;
        const currentMinute = now - now % 60000;
        this.onlineVisiors = visitors;
        this.onlineVisitorsByMinute[currentMinute] = Math.max(
          this.onlineVisitorsByMinute[currentMinute] || 0, visitors);

        let timeseries = Object.keys(this.onlineVisitorsByMinute).sort().reverse().map(minute => {
          return [new Date(minute * 1), this.onlineVisitorsByMinute[minute]];
        }).sort();
        timeseries = timeseries.slice(timeseries.length - 10);

        const timeseriesValues = timeseries.map(([_, x]) => x);
        const previousValues = this.onlineVisitorsTimeseries.map(([_, x]) => x);
        if (!arraysEqual(timeseriesValues, previousValues)) {
          this.onlineVisitorsTimeseries = timeseries;
        }
      },

      visitorLocationsChanged(locations) {
        this.liveLocations = locations;
      }
    },
  };
</script>

<style type="scss">
  .totals {
    display: grid;
    row-gap: 1rem;
    padding: 1rem;
  }

  .charts,
  .reports {
    display: grid;
    row-gap: 1rem;
    padding: 1rem;
  }

  .apexcharts-svg {
    border-radius: 4px;
  }

  @media (min-width: 640px) {
    .totals {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr;
    }
  }

  @media (min-width: 1024px) {
    .totals {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr 1fr 1fr;
    }

    .totals-box:nth-child(3) {
      grid-column: auto;
    }

    .reports {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr;
    }

    .reports--wide {
      grid-template-columns: 1fr;
    }
  }
</style>
