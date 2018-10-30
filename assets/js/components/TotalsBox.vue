<template>
  <div class="totals-box" v-bind:class="{ 'totals-box--active': active }">
    <h2 class="totals-box__value">{{ value }}</h2>
    <h6 class="totals-box__label">{{ label }}</h6>
  </div>
</template>

<script>
  export default {
    props: ["label", "value", "active"]
  };
</script>

<style lang="scss">
  .totals-box {
    padding: 1rem 1.5rem;
    background: #4648ff;
    border-bottom: 1px solid #ffffff10;
    border-right: 1px solid #ffffff10;
    border-radius: 8px;
    box-shadow: 0 0 30px #4648ff54;
    color: #fff;
    font-size: 1.4rem;
    opacity: 0.5;
    transition: opacity 0.5s ease-in-out;

    &:hover {
      opacity: 0.9;
    }

    &--active,
    &--active:hover {
      opacity: 1;
    }

    &__value {
      font-weight: 600;
      text-transform: lowercase;
    }
  }
</style>
