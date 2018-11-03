<template>
  <card :no-padding="true">
    <table class="table">
      <thead>
        <tr>
          <th>Referrer</th>
          <th>Visits</th>
          <th>Sess.</th>
          <th>Visitors</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="referrer in referrers">
          <td><a :href="referrer.uri" target="_new">{{ referrer.host }}{{ referrer.path }}</a></td>
          <td>{{ referrer.visits }}</td>
          <td>{{ referrer.sessions }}</td>
          <td>{{ referrer.visitors }}</td>
        </tr>

        <tr v-if="!referrers.length">
          <td colspan="4"><em>No data for the current date range.</em></td>
        </tr>
      </tbody>
    </table>
  </card>
</template>

<script>
  import { numeric } from "../lib/formatting.js";

  import Card from "./Card.vue";

  export default {
    components: {Card},
    props: {
      breakdown: {
        type: Array,
        required: true,
      }
    },

    computed: {
      referrers() {
        return this.breakdown.map(({ host, path, visits, visitors, sessions }) => ({
          host, path,
          uri: `http://${host}${path}`,
          visits: numeric(visits),
          visitors: numeric(visitors),
          sessions: numeric(sessions),
        }));
      }
    }
  };
</script>
