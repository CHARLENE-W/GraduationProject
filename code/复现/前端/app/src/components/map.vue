<template>
  <div>
    <div id="map"></div>
    <search-box ></search-box>
  </div>
</template>
<script>
/*
  地图组件
*/
import global_ from "./Global";
import { getRoads } from "../../static/js/getRoads.js";
import { update_map } from "../../static/js/mapConfig.js";
import searchBox from "./searchBox.vue";
const initPosGeohash = "wx4enz9fy7cp";

export default {
  name: "mapContent",
  components: { searchBox},
  mounted() {
      //  getRoads("wx4er");
    this.initMap();
    this.genMap();
    if(global_.startGeohash){
      if(global_.startPoint) global_.map.removeLayer(global_.startPoint)
      global_.startPoint= this.genCircle(global_.startGeohash,20,"#2894FF")
      global_.startPoint.addTo(global_.map)
    }
    if(global_.dstGeohash){
          if(global_.dstPoint) global_.map.removeLayer(global_.dstPoint)
      global_.dstPoint= this.genCircle(global_.dstGeohash,20,"#FF8040")
      global_.dstPoint.addTo(global_.map)
    }
  },
computed:{
          getNearset(){
      
          }
},
  methods: {
    initMap: function () {
      console.log(">>>Init the map...");
      global_.map = L.map("map", { maxZoom: 18, minZoom: 1 }).setView(
        initPosGeohash,
        14
      );
    },
    initNearest: function (geohash) {
     
    },

    genMap: function () {
      update_map(global_.map);
    },
  },
};
</script>
<style>
#map {
  width: 100%;
  height: 100%;
  position: absolute;
  overflow: hidden;
  background-color: rgba(255, 240, 192, 0.746);
}
input {
  height: 40px;
  width: 100px;
  margin: 10px;
}
</style>