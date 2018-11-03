import Vue from "vue";
import VueApexCharts from "vue-apexcharts";
import VueRouter from "vue-router";

Vue.use(VueApexCharts);
Vue.use(VueRouter);

import App from "./App.vue";
import Dashboard from "./pages/Dashboard.vue";
import Tracking from "./pages/Tracking.vue";

const routes = [
  { path: "/", component: Dashboard },
  { path: "/tracking", component: Tracking }
];
const router = new VueRouter({ routes });
const app = new Vue({ render: h => h(App), router });

app.$mount("#app");
