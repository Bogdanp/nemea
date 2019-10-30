<template>
  <card :no-padding="true">
    <table class="table">
      <thead>
        <tr>
          <th>Live Hits</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="location in locations">
          <td><a :href="location">{{ location }}</a></td>
        </tr>

        <tr v-if="!locations.length">
          <td><em>There are currently no visitors on the website.</em></td>
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
      locations: {
        type: Array,
        required: true,
      }
    },
  };
</script>
