<template>
  <div class="totals-box totals-box"
       v-on:click.capture="$emit('activate', id)"
       v-bind:class="{ 'totals-box--active': active }">
    <h2 class="totals-box__value">{{ formattedValue }}</h2>
    <h6 class="totals-box__label">{{ label }}</h6>
  </div>
</template>

<script>
  import { duration, numeric } from "../lib/formatting.js";

  const FORMATTERS = { duration, numeric };

  export default {
    props: {
      id: {
        type: String,
        required: true,
      },

      label: {
        type: String,
        required: true,
      },

      value: {
        type: Number,
        required: true,
      },

      active: {
        type: Boolean,
        default: false,
      },

      formatter: {
        type: String,
        default: "numeric",
      },
    },

    computed: {
      formattedValue() {
        return FORMATTERS[this.formatter](this.value);
      }
    }
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
    transition: opacity 0.3s ease-in-out;

    &:hover {
      opacity: 0.9;
    }

    &--active,
    &--active:hover {
      opacity: 1;
    }

    &__value {
      font-weight: 600;
      letter-spacing: 0;
      text-transform: uppercase;
    }
  }
</style>
