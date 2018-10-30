<template>
  <div class="container">
    <div class="totals">
      <totals-box label="Visits" value="8,351" active="true"></totals-box>
      <totals-box label="Sessions" value="8,200"></totals-box>
      <totals-box label="Visitors" value="8,001"></totals-box>
      <totals-box label="Avg. Time on Site" value="50s"></totals-box>
    </div>
    <div class="charts">
      <area-chart></area-chart>
    </div>
  </div>
</template>

<script>
  import TotalsBox from "../components/TotalsBox.vue";

  export default {
    name: "Dashboard",
    components: {TotalsBox}
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
