<template>
  <div class="app">
    <div class="nav">
      <div class="container">
        <ul class="nav__items">
          <li class="nav__item nav__item--active">
            <a href="#/">Dashboard</a>
          </li>
          <li class="nav__item">
            <a href="#/settings">Settings</a>
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
  export default {};
</script>
