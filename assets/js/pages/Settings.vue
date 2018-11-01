<template>
  <div class="container">
    <div class="content">
      <tracking-code></tracking-code>
    </div>
  </div>
</template>

<script>
  import TrackingCode from "../components/TrackingCode.vue";

  export default {
    name: "Settings",
    components: {TrackingCode},
  };
</script>
