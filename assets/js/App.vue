<template>
  <div class="app">
    <div class="nav">
      <div class="container">
        <ul class="nav__items">
          <router-link to="/" tag="li" class="nav__item" active-class="nav__item--active" exact>
            <a>Dashboard</a>
          </router-link>
          <router-link to="/tracking" tag="li" class="nav__item" active-class="nav__item--active">
            <a>Tracking</a>
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
  export default {};
</script>
