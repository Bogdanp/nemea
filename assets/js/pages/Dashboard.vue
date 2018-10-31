<template>
  <div class="container">
    <div class="totals">
      <totals-box id="visits" label="Visits" :value="8351" :active="true" @activate="onActivate"></totals-box>
      <totals-box id="sessions" label="Sessions" :value="8200" @activate="onActivate"></totals-box>
      <totals-box id="visitors" label="Visitors" :value="8001" @activate="onActivate"></totals-box>
      <totals-box id="time" label="Avg. Time on Site" :value="65" formatter="duration" @activate="onActivate"></totals-box>
    </div>
    <div class="charts">
    </div>
  </div>
</template>

<script>
  import TotalsBox from "../components/TotalsBox.vue";

  export default {
    name: "Dashboard",
    components: {TotalsBox},

    methods: {
      onActivate(id) {
        console.log(id);
      }
    }
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
