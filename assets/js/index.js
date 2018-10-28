import Vue from "vue";
import VueRouter from "vue-router";

Vue.use(VueRouter);

import Dashboard from "./pages/Dashboard.vue";

const routes = [{ path: "/", component: Dashboard }];
const router = new VueRouter({ routes });
const app = new Vue({ router });

app.$mount("#app");
