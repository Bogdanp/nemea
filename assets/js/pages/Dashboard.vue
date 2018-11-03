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

    <div class="reports">
      <top-pages :breakdown="report['pages-breakdown']"></top-pages>
      <top-referrers :breakdown="report['referrers-breakdown']"></top-referrers>
    </div>
  </div>
</template>

<script>
  import { capitalize } from "../lib/strings.js";
  import { datesInRange, formatDate, makeContinuous } from "../lib/dates.js";
  import { numeric } from "../lib/formatting.js";
  import { getDailyReport} from "../lib/reporting.js";
  import { makeTimeseriesOptions } from "../lib/charts.js";

  import Card from "../components/Card.vue";
  import TopPages from "../components/TopPages.vue";
  import TopReferrers from "../components/TopReferrers.vue";
  import TotalsBox from "../components/TotalsBox.vue";

  import VueApexCharts from "vue-apexcharts";
  import addDays from "date-fns/add_days";
  import differenceInDays from "date-fns/difference_in_days";
  import subDays from "date-fns/sub_days";
  import startOfDay from "date-fns/start_of_day";
  import startOfTomorrow from "date-fns/start_of_tomorrow";
  import startOfToday from "date-fns/start_of_today";
  import startOfYesterday from "date-fns/start_of_today";

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
      TopPages,
      TopReferrers,
      TotalsBox,

      chart: VueApexCharts,
    },

    data() {
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
      };
    },

    created() {
      getDailyReport(this.startDate, this.endDate)
        .then(report => {
          this.report = report;
        });
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
        const previousTimeseries = makeContinuous(
          this.startDate,
          this.endDate,
          this.report.timeseries[0].map(data => ({
            date: addDays(new Date(data.date), this.daysInRange),
            value: data[this.currentReport],
          }))
        );

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
            name: capitalize(this.currentReport),
            data: currentTimeseries,
          }];
        } else {
          return [{
            name: capitalize(this.currentReport),
            data: currentTimeseries,
          }, {
            name: "Previously",
            data: previousTimeseries,
          }];
        }
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

    .totals-box:nth-child(3) {
      grid-column: 1 / 3;
    }
  }

  @media (min-width: 1024px) {
    .totals {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr 1fr;
    }

    .totals-box:nth-child(3) {
      grid-column: auto;
    }

    .reports {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr;
    }
  }
</style>
