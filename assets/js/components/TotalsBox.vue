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
  @import "../../css/_colors.scss";

  .totals-box {
    padding: 1rem 1.5rem;
    background: $background-highlight-gradient;
    border-radius: 4px;
    box-shadow: 0 2px 5px $shadow-highlight;
    color: $text-highlight;
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
