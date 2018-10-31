<template>
  <div class="container">
    <div class="content">
      <card title="Tracking Code">
        <p>
          Embed this script in the <code>body</code> of every page on
          your website to begin tracking:
        </p>
      </card>
    </div>
  </div>
</template>

<script>
  import Card from "../components/Card.vue";

  export default {
    name: "Settings",
    components: {Card},
  };
</script>

<style lang="scss">
  .content {
    padding: 1rem;
  }
</style>
