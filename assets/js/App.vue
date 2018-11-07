<template>
  <div class="app">
    <div class="nav">
      <div class="container">
        <ul class="nav__items">
          <router-link to="/" tag="li" class="nav__item" active-class="nav__item--active" exact>
            <a>Dashboard</a>
          </router-link>
          <router-link to="/setup" tag="li" class="nav__item" active-class="nav__item--active">
            <a>Setup</a>
          </router-link>

          <li class="nav__item" v-if="returnURL" style="float: right;">
            <a :href="returnURL">Back to Your Sites</a>
          </li>
        </ul>
      </div>
    </div>

    <div class="page">
      <router-view></router-view>
    </div>
  </div>
</template>

<script>
  import { parseCookies } from "./lib/cookies.js";

  export default {
    data() {
      const cookies = parseCookies();

      return {
        returnURL: cookies["ret"] || null,
      };
    }
  };
</script>
