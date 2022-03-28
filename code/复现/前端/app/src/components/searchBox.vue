<template>
  <div>
    <traffic ref="myTraffic" @clear="clear" v-show="isManaging"></traffic>
    <search-start
      :data="isSearchStart"
      @changeStartComponent="changeStart"
      v-if="isSearchStart"
    ></search-start>
    <search-dst
      :data="isSearchDst"
      @changeDstComponent="changeDst"
      v-if="isSearchDst"
    ></search-dst>
    <div
      class="searchbox-main"
      v-if="!isManaging && !isSearchDst && !isSearchStart"
    >
      <div class="searchbox-container">
        <div class="start">
          <div class="icon"></div>
          <input
            autocomplete="false"
            type="text"
            placeholder="请输入上车位置"
            class="text-overflow"
            v-model="startPlace"
            @click="searchStart"
          />
        </div>
        <div class="line"></div>
        <div class="destination">
          <div class="icon"></div>
          <input
            autocomplete="false"
            type="text"
            placeholder="您要去哪里?"
            class="text-overflow"
            v-model="dstPlace"
            @click="searchDst"
          />
        </div>
        <input
          class="button"
          type="button"
          @click="manageVehicle"
          v-show="isStartManaging && !isManaging"
          value="开始调度车辆"
        />
        <div class="dots">
          <div class="dot"></div>
          <div class="dot"></div>
          <div class="dot"></div>
          <div class="dot"></div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import searchStart from "./searchStart.vue";
import searchDst from "./searchDst.vue";
import global_ from "./Global.vue";
import Traffic from "./Traffic.vue";
export default {
  name: "searchBox",
  data() {
    return {
      isClicked: false,
      startPlace: "",
      dstPlace: "",
      isSearchStart: false,
      isSearchDst: false,
      isStartManaging: false,
      isManaging: false,
    };
  },
  components: {
    searchStart,
    searchDst,
    Traffic,
  },
  methods: {
    searchStart: function () {
      console.log("search start");
      this.isSearchStart = true;
    },
    searchDst: function () {
      console.log("search destination");
      this.isSearchDst = true;
    },
    changeDst: function (params) {
      this.isSearchDst = false;
      console.log("??:" + params);
      this.dstPlace = params;
      if (this.startPlace !== "") {
        this.isStartManaging = true;
      } else {
        this.isStartManaging = false;
      }
    },

    changeStart: function (params) {
      this.isSearchStart = false;
      console.log("??:" + params);
      this.startPlace = params;
      if (this.dstPlace !== "") {
        this.isStartManaging = true;
      } else {
        this.isStartManaging = false;
      }
    },
    manageVehicle: function () {
      if (!this.isClicked) {
        this.isClicked=true;
        if (this.startPlace !== "" && this.dstPlace !== "") {
          this.$refs.myTraffic.initPassenger().then(() => {
            this.$refs.myTraffic.manageVehicle();
            this.isManaging = true;
          });
        }
      }
    },
    clear: function () {
      this.startPlace = "";
      this.dstPlace = "";
      this.isClicked=false;
      this.isSearchStart = false;
      this.isSearchDst = false;
      this.isStartManaging = false;
      this.isManaging = false;
    },
  },
};
</script>
<style>
.searchbox-container {
  padding: 8px 23px 8px 21px;
}
.searchbox-container .icon {
  width: 10px;
  height: 10px;
  background: #fff;
  border: 3px solid #6ad69f;
  border-radius: 50%;
  -webkit-box-sizing: border-box;
  box-sizing: border-box;
}
.searchbox-container .dots {
  display: -webkit-box;
  -webkit-box-pack: justify;
  display: -ms-flexbox;
  display: flex;
  position: absolute;
  -webkit-box-orient: vertical;
  -webkit-box-direction: normal;
  -ms-flex-direction: column;
  flex-direction: column;
  -ms-flex-pack: justify;
  justify-content: space-between;
  height: 18px;
  top: 46px;
  left: 24px;
  -webkit-transform: translateY(-50%);
  transform: translateY(-50%);
}
.searchbox-container .dots .dot {
  width: 3px;
  height: 3px;
  background: #ddd;
  border-radius: 50%;
}
.start input,
.destination input {
  -webkit-box-flex: 1;
  -ms-flex-positive: 1;
  flex-grow: 1;
  margin-left: 12px;
  font-size: 16px;
  color: #333;
}
.searchbox-container .line {
  background: #eaeaea;
  height: 1px;
  margin-left: 25px;
}
.searchbox-container .destination,
.searchbox-container .start {
  display: -webkit-box;
  -webkit-box-align: center;
  display: -ms-flexbox;
  display: flex;
  -ms-flex-align: center;
  align-items: center;
  height: 37px;
}
.searchbox-main {
  position: absolute;
  z-index: 10;
  left: 8px;
  right: 8px;
  bottom: 8px;
  background: #fff;
  border-radius: 5px;
  -webkit-box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.15);
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.15);
}
.searchbox-container .destination .icon {
  border-color: #ef4f4f;
}
.text-overflow {
  text-overflow: ellipsis;
  overflow: hidden;
  white-space: nowrap;
}
input {
  background: none;
  outline: none;
  border: none;
}
</style>