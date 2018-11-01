<template>
  <div class="card">
    <div class="card__header" v-if="title || $slots.header">
      <slot name="header">
        <h1>{{ title }}</h1>
      </slot>
    </div>

    <div class="card__content">
      <slot></slot>
    </div>

    <div class="card__footer" v-if="$slots.footer">
      <slot name="footer">
      </slot>
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      title: {
        type: String,
        default: null,
      }
    }
  };
</script>

<style lang="scss">
  @import "../../css/_colors.scss";

  .card {
    background: $background;
    border: 1px solid $shadow;
    border-radius: 4px;
    box-shadow: 0 3px 5px $shadow;

    &__header {
      border-bottom: 1px solid $shadow-darker;
      border-radius: 4px 4px 0 0;
      padding: 1rem;

      h1 {
        font-size: 1rem;
        font-weight: 400;
        letter-spacing: 0;
        text-transform: none;
      }
    }

    &__content {
      padding: 1rem;
    }

    &__footer {
      background: #f9f9f9;
      border-top: 1px solid $shadow-darker;
      border-radius: 0 0 4px 4px;
      padding: 1rem;
    }
  }
</style>
