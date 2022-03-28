<template>
  <div id="app">
     <router-view ></router-view>
     <login></login>
  </div>
</template>

<script>
import mapContent from "./components/map.vue";
import Login from "./components/Login.vue";
export default {
  name: "App",
  components: {
    mapContent,
    Login,
  },
};
</script>

<style>
</style>
