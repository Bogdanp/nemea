<template>
  <div class="container">
    <div class="content">
      <card title="Tracking Code" :no-padding="true">
        <p>
          Embed this script in the <code>body</code> of every page on
          your website to begin collecting data:
        </p>
        <pre>&lt;script>
{{ script }}
&lt;/script></pre>
      </card>
    </div>
  </div>
</template>

<script>
  import Card from "../components/Card.vue";

  const trackURI = `${window.location.host}${window.location.pathname}track.js`;
  const script = `
(function(n, e, m, E, a, $) {
  n[E]=n[E]||function(){(n[E].q=n[E].q||[]).push(arguments)};$=e.createElement(m);
  $.id=E;$.src=a;$.async=1;m=e.getElementsByTagName(m)[0];m.parentNode.insertBefore($,m)
})(window, document, "script", "nemea", "//${trackURI}");

nemea("view");
`.trim().replace(/</g, "&lt;");

  export default {
    name: "Settings",
    components: {Card},

    data() {
      return { script };
    }
  };
</script>

<style lang="scss">
  @import "../../css/_colors.scss";

  .content {
    padding: 1rem;
  }

  p {
    padding: 1rem;
  }

  pre {
    background: $shadow;
    border-radius: 0 0 4px 4px;
    padding: 1rem;
  }
</style>
