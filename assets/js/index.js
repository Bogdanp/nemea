import Vue from "vue";
import VueApexCharts from "vue-apexcharts";
import VueRouter from "vue-router";

Vue.use(VueApexCharts);
Vue.use(VueRouter);

import App from "./App.vue";
import Dashboard from "./pages/Dashboard.vue";
import Setup from "./pages/Setup.vue";

const routes = [
  { path: "/", component: Dashboard },
  { path: "/setup", component: Setup }
];
const router = new VueRouter({ routes });
const app = new Vue({ render: h => h(App), router });

app.$mount("#app");
