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
(function(r, o, c, k, e, t, m, a, n) {
  r[e]=r[e]||function(){(r[e].q=r[e].q||[]).push(arguments)};t=o.createElement(c);
  t.id=e;t.src=k;t.async=1;m=o.getElementsByTagName(c)[0];m.parentNode.insertBefore(t,m);
})(window, document, "script", "//${trackURI}", "nemea");

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
