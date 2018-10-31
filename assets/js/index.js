import Vue from "vue";
import VueRouter from "vue-router";

Vue.use(VueRouter);

import App from "./App.vue";
import Dashboard from "./pages/Dashboard.vue";
import Settings from "./pages/Settings.vue";

const routes = [
  { path: "/", component: Dashboard },
  { path: "/settings", component: Settings }
];
const router = new VueRouter({ routes });
const app = new Vue({ render: h => h(App), router });

app.$mount("#app");
