import Vue from "vue";
import VueRouter from "vue-router";

Vue.use(VueRouter);

import App from "./App.vue";
import Dashboard from "./pages/Dashboard.vue";

const routes = [{ path: "/", component: Dashboard }];
const router = new VueRouter({ routes });
const app = new Vue({ render: h => h(App), router });

app.$mount("#app");
