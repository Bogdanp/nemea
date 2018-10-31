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
    </div>
  </div>
</template>

<script>
  import { getDailyReport} from "../lib/reporting.js";

  import TotalsBox from "../components/TotalsBox.vue";

  export default {
    name: "Dashboard",
    components: {TotalsBox},

    data() {
      return {
        currentReport: "visits",
        report: {
          totals: {
            visits: 0,
            sessions: 0,
            visitors: 0,
            "avg-time": 0,
          },
          breakdown: [],
        },
      };
    },

    created() {
      getDailyReport()
        .then(report => {
          this.report = report;
        });
    },

    methods: {
      reportChanged(id) {
        this.currentReport = id;
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
  }
</style>
