<template>
  <div class="app">
    <div class="nav">
      <div class="container">
        <ul class="nav__items">
          <li class="nav__item">
            <a :href="returnURL" class="logo">nemea</a>
          </li>

          <router-link to="/" tag="li" class="nav__item" active-class="nav__item--active" exact>
            <a>Dashboard</a>
          </router-link>
          <router-link to="/setup" tag="li" class="nav__item" active-class="nav__item--active">
            <a>Setup</a>
          </router-link>
        </ul>
      </div>
    </div>

    <div class="page">
      <router-view></router-view>
    </div>
  </div>
</template>

<script>
  import { deleteCookie, parseCookies } from "./lib/cookies.js";
  import { visitorTracker } from "./lib/reporting.js";

  const ONBOARDING_COOKIE = "onboarding";

  export default {
    created() {
      const cookies = parseCookies();

      if (cookies[ONBOARDING_COOKIE]) {
        try {
          this.$router.push({ path: "/setup" });
        } finally {
          deleteCookie(ONBOARDING_COOKIE);
        }
      }

      const initialTitle = document.title;
      visitorTracker.addListener((visitors) => {
        if (visitors > 1) {
          document.title = `${visitors} visitors online :: ${initialTitle}`;
        } else if (visitors === 1) {
          document.title = `${visitors} visitor online :: ${initialTitle}`;
        } else {
          document.title = initialTitle;
        }
      });
    },

    data() {
      const cookies = parseCookies();

      return {
        returnURL: cookies["ret"] || "/",
      };
    }
  };
</script>
