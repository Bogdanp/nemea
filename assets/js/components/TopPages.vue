<template>
  <card :no-padding="true">
    <table class="table">
      <thead>
        <tr>
          <th>Page</th>
          <th>Visits</th>
          <th>Sess.</th>
          <th>Visitors</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="page in pages">
          <td><a :href="page.uri" target="_new">{{ page.path }}</a></td>
          <td>{{ page.visits }}</td>
          <td>{{ page.sessions }}</td>
          <td>{{ page.visitors }}</td>
        </tr>

        <tr v-if="!pages.length">
          <td colspan="4"><em>No data for the current date range.</em></td>
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
        return this.breakdown.map(({ host, path, visits, visitors, sessions }) => ({
          host, path, visits, visitors, sessions,
          uri: `http://${host}${path}`,
        }));
      }
    }
  };
</script>
