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
      </tbody>
    </table>
  </card>
</template>

<script>
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
      pages() {
        return this.breakdown.map((data) => ({
          uri: `http://${data["referrer-host"]}${data["referrer-path"]}`,
          host: data["referrer-host"],
          path: data["referrer-path"],
          visits: data.visits,
          visitors: data.visitors,
          sessions: data.sessions,
        })).sort((a, b) => b.visits - a.visits);
      }
    }
  };
</script>
