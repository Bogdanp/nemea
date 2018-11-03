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

      <totals-box id="avg-time" label="Avg. Time on Site" formatter="duration"
                  :value="report.totals['avg-time']"
                  :active="currentReport == 'avg-time'"
                  @activate="reportChanged"></totals-box>
    </div>

    <div class="charts">
      <card :no-padding="true">
        <chart type="area" :height="chartHeight" :options="chartOptions" :series="series"></chart>
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
  import { datesInRange, makeContinuous } from "../lib/dates.js";
  import { getDailyReport} from "../lib/reporting.js";
  import { makeTimeseriesOptions } from "../lib/charts.js";

  import Card from "../components/Card.vue";
  import TopPages from "../components/TopPages.vue";
  import TopReferrers from "../components/TopReferrers.vue";
  import TotalsBox from "../components/TotalsBox.vue";

  import addDays from "date-fns/add_days";
  import differenceInDays from "date-fns/difference_in_days";
  import subDays from "date-fns/sub_days";
  import startOfDay from "date-fns/start_of_day";
  import startOfTomorrow from "date-fns/start_of_tomorrow";
  import startOfToday from "date-fns/start_of_today";
  import VueApexCharts from "vue-apexcharts";

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
        startDate: subDays(startOfToday(), 6),
        endDate: startOfTomorrow(),
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
      chartOptions() {
        const options = makeTimeseriesOptions();
        options.chart.sparkline = { enabled: true };
        options.grid.padding.top = 0;
        options.grid.padding.left = 0;
        options.grid.padding.right = 0;

        return options;
      },

      chartHeight() {
        return window.innerWidth < 720 ? 220 : 300;
      },

      series() {
        const delta = differenceInDays(this.endDate, this.startDate);

        const previousTimeseries = makeContinuous(
          this.startDate,
          this.endDate,
          this.report.timeseries[0].map(data => ({
            date: addDays(new Date(data.date), delta),
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

        return [{
          name: capitalize(this.currentReport),
          data: currentTimeseries,
        }, {
          name: "Previously",
          data: previousTimeseries,
        }];
      },
    },

    methods: {
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
  }

  @media (min-width: 1024px) {
    .totals {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr 1fr 1fr;
    }

    .reports {
      column-gap: 1rem;
      grid-template-columns: 1fr 1fr;
    }
  }
</style>
