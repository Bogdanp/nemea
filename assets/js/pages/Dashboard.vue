<template>
  <div class="container">
    <div class="totals">
      <totals-box label="Visits" value="8,351" active="true"></totals-box>
      <totals-box label="Visitors" value="8,001"></totals-box>
      <totals-box label="Avg. Time on Site" value="50s"></totals-box>
      <totals-box label="Bounce Rate" value="30%"></totals-box>
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
    padding: 1rem;
  }

  @media (min-width: 1024px) {
    .totals {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr 1fr;
      padding: 2rem 0;
    }
  }
</style>
