<template>
  <div>
    <div class="dache-plan-root">
      <div class="dache-plan-content">
        <div class="partners-container">
          <div class="partners-wrapper">
            <ul class="partners" v-show="passengerId !== ''">
              <li class="partner-item-c">
                <div>
                  <img
                    src="https://map-mobile-resource.cdn.bcebos.com/icon/rec/taxi/default/feidi_siji%403x1013.png"
                    class="logo"
                    style="width: 30px; height: 30px; margin-right: 3px"
                  />
                  <span class="name text-overflow">{{ passengerId }}</span>
                </div>
                <span class="price-desc text-overflow"
                  >乘客位置：<span style="font-size: 20px">{{
                    passengerPlace
                  }}</span>
                  <br />
                  乘客目的地：<span style="font-size: 20px">{{
                    endPlace
                  }}</span>
                </span>
              </li>
            </ul>
          </div>
        </div>
        <div class="btn-container">
          <div class="button pickup" @click="pickUp()" v-if="!isPickedUp">
            确认接该乘客
          </div>
          <div class="button nopickup" @click="noPickUp()" v-if="!isPickedUp">
            拒绝接该乘客
          </div>
          <div class="button Msg" v-if="isPickedUp">{{ btnMsg }}</div>
        </div>
        <!---->
      </div>
      <!----><!---->
    </div>
  </div>
</template>
<script>
/*
  事件组件
*/
import global_ from "../components/Global.vue";
export default {
  name: "Traffic",
  data() {
    return {
      passengerId: "",
      passengerGeohash: "",
      passengerPlace: "",
      endGeohash: "",
      endPlace: "",
      startPoint: null,
      endPoint: null,
      astarTimes: [],
      isPickedUp: false,
      btnMsg: "",
      vehicleGroup: null,
      togetherGroup: null,
    };
  },
  mounted() {
    var trafficContract = global_.trafficContract;
    var web3Map = global_.web3Map;
    var vehicleId = global_.userID;
    //event
    trafficContract.events.Myevent((error, event) => {
      var map = global_.map;
      if (error != null) {
        console.log("Myevent_error: ", error);
      }
      //whether to pick up the passenger
      if (
        event.returnValues.vehicleId.slice(0, 42) == vehicleId.toLowerCase()
      ) {
        console.log(event);
        this.passengerId = event.returnValues.passengerId;

        //获取乘客上车地，并绘制
        this.passengerGeohash = web3Map.utils
          .hexToAscii(event.returnValues.passengerGeohash)
          .slice(0, 11);
        this.passengerPlace = global_.geoToPalceMap.get(this.passengerGeohash);

        this.startPoint = L.circle(this.passengerGeohash, 10, {
          color: "#00CCFF",
        });
        map.addLayer(this.startPoint);

        //获取乘客目的地，并绘制
        trafficContract.methods
          .getPassengerEnd(this.passengerId)
          .call({ from: vehicleId, gas: 50000000 })
          .then((result) => {
            this.endGeohash = web3Map.utils.hexToAscii(result).slice(0, 11);
            console.log("目的地坐标:", this.endGeohash);
            this.endPlace = global_.geoToPalceMap.get(this.endGeohash);
            this.endPoint = L.circle(this.endGeohash, 10, { color: "#FF0000" });
            map.addLayer(this.endPoint);
          });
      }
    });
    //监听乘客付款事件
    trafficContract.events.payEvent((error, event) => {
      var endGeohash = global_.endGeohash;
      if (error != null) {
        console.log("payEvent_error: ", error);
      }
      if (
        event.returnValues.vehicleId.slice(0, 42) == vehicleId.toLowerCase()
      ) {
        console.log("payEvent: " + vehicleId + "乘客已付款");
        this.btnMsg = "乘客付款成功，等待清空数据...";
        trafficContract.methods
          .setVehicleStatusEmpty(vehicleId)
          .send({
            from: vehicleId,
            gas: 500000,
            position: endGeohash,
            txtime: Date.now(),
          })
          .then((result) => {
            trafficContract.methods
              .setVehicle(vehicleId, web3Map.utils.asciiToHex(endGeohash))
              .send({
                from: vehicleId,
                gas: 500000,
                position: endGeohash,
                txtime: Date.now(),
              })
              .then((result) => {
                console.log("置状态为空车");
                this.clear();
              });
          });
      }
    });

    //监听乘客上车事件
    trafficContract.events.boardEvent((error, event) => {
      if (error != null) {
        console.log("boardEvent_error: ", error);
      }
      if (
        event.returnValues.vehicleId.slice(0, 42) == vehicleId.toLowerCase()
      ) {
        console.log("boardEvent: " + vehicleId + "乘客已上车");
        this.btnMsg = "确认乘客已上车";
        console.log("执行了调度算法,车辆到达乘客所在位置");
        this.manageToEnd();
      }
    });
  },
  methods: {
    //确认接乘客
    pickUp: async function () {
      var vehicleLayers = [];
      var trafficContract = global_.trafficContract;
      var mapContract = global_.mapContract;
      var web3Map = global_.web3Map;
      var map = global_.map;
      var vehicleId = global_.userID;
      var vehiclePosition = global_.userGeohash;
      var passengerId = this.passengerId;
      var passengerGeohash = this.passengerGeohash;
      this.isPickedUp = true;
      this.btnMsg = "请前往乘客出发地: "+this.passengerPlace;
      if (vehiclePosition == passengerGeohash) {
        //store route
        trafficContract.methods
          .storeRoutes(0, vehicleId, passengerId, [])
          .send({
            from: vehicleId,
            gas: 8000000,
            position: vehiclePosition,
            txtime: Date.now(),
          })
          .then(
            (result) => {
              this.vehicleGroup = L.layerGroup(vehicleLayers);
              map.addLayer(vehicleGroup);
              console.log("存储路径成功");
            },
            function (error) {
              console.log("存储路径失败:", error);
            }
          );
      } else {
        let astarTime1 = Date.now();

        mapContract.methods
          .astar(
            web3Map.utils.asciiToHex(vehiclePosition),
            web3Map.utils.asciiToHex(passengerGeohash)
          )
          .call({ from: vehicleId, gas: 50000000000 })
          .then(
            (result) => {
              let astarTime2 = Date.now() - astarTime1;
              let countFrag = 0;
              for (let i = 0; i < result[0].length; i++) {
                if (
                  result[0][i].toString() !=
                  "0x0000000000000000000000000000000000000000000000000000000000000000"
                ) {
                  countFrag++;
                }
              }
              this.astarTimes.push({
                astarTime2,
                countFrag,
              });
              console.log("路径规划用时：", astarTime2, "ms");
              console.log("astar-result: ", result);
              let astarOriginRoute = result[0];
              let costAll = Number(result[1]);
              console.log("车辆行驶时间：", costAll);
              //store route
              trafficContract.methods
                .storeRoutes(costAll, vehicleId, passengerId, astarOriginRoute)
                .send({
                  from: vehicleId,
                  gas: 8000000,
                  position: vehiclePosition,
                  txtime: Date.now(),
                })
                .then(
                  function (result) {
                    console.log("存储路径成功");
                  },
                  function (error) {
                    console.log("存储路径失败:", error);
                  }
                );
              let astarRoute = [];
              for (let i = 0; i < result[0].length; i++) {
                if (
                  result[0][i].toString() !=
                  "0x0000000000000000000000000000000000000000000000000000000000000000"
                ) {
                  let temp = web3Map.utils
                    .hexToAscii(result[0][i])
                    .slice(0, 11);
                  astarRoute.push(temp);
                }
              }
              astarRoute.reverse();
              console.log("astar: ", astarRoute);
              //add route point to map
              function draw2(p, q) {
                if (q == astarRoute.length) {
                  return 1;
                }
                function doit2(geohash1, geohash2) {
                  console.log("geohash1, geohash2: ", geohash1, geohash2);
                  let route = L.polyline([geohash1, geohash2], {
                    color: "#FFFF00",
                    fillColor: "#FFFF00",
                    fillOpacity: 1,
                    weight: 7,
                  });
                  vehicleLayers.push(route);
                }
                setTimeout(doit2(astarRoute[p], astarRoute[q]), 0);
                draw2(p + 1, q + 1);
              }
              draw2(0, 1);
              this.vehicleGroup = L.layerGroup(vehicleLayers);
              map.addLayer(this.vehicleGroup);
            },
            function (err) {
              console.error("astarErr: ", err);
            }
          );
      }
    },
    noPickUp: async function () {
      var trafficContract = global_.trafficContract;
      var vehicleId = global_.userID;
      var passengerId = this.passengerID;
      var vehiclePosition = global_.userGeohash;
      console.log("选择不去接乘客");
      trafficContract.methods
        .setRejectVehicleStatus(vehicleId, passengerId)
        .send({
          from: vehicleId,
          gas: 5000000000,
          position: vehiclePosition,
          txtime: Date.now(),
        })
        .then(function (result) {
          console.log("状态转为空车");
        });
      this.clear();
    },

    manageToEnd: async function () {
      var togetherLayers = [];
      var trafficContract = global_.trafficContract;
      var mapContract = global_.mapContract;
      var web3Map = global_.web3Map;
      var map = global_.map;
      var vehicleId = global_.userID;
      var passengerId = this.passengerId;
      var passengerGeohash = this.passengerGeohash;
      let astarTime1 = Date.now();
      mapContract.methods
        .astar(
          web3Map.utils.asciiToHex(passengerGeohash),
          web3Map.utils.asciiToHex(this.endGeohash)
        )
        .call({ from: vehicleId, gas: 50000000000 })
        .then(
          (result) => {
            let astarTime2 = Date.now() - astarTime1;
            let countFrag = 0;
            for (let i = 0; i < result[0].length; i++) {
              if (
                result[0][i].toString() !=
                "0x0000000000000000000000000000000000000000000000000000000000000000"
              ) {
                countFrag++;
              }
            }
            this.astarTimes.push({
              astarTime2,
              countFrag,
            });
            console.log("路径规划用时：", astarTime2, "ms");
            this.btnMsg =
              "请前往 " + this.endPlace + "  计划用时" + astarTime2 + " ms";
            console.log("astar-result: ", result);
            let astarOriginRoute = result[0];
            let costAll = Number(result[1]);
            trafficContract.methods
              .storeRoutes(costAll, vehicleId, passengerId, astarOriginRoute)
              .send({
                from: vehicleId,
                gas: 5000000,
                position: passengerGeohash,
                txtime: Date.now(),
              })
              .then(function (result) {
                console.log("存储路径成功");
              });
            let astarRoute = [];
            for (let i = 0; i < result[0].length; i++) {
              if (
                result[0][i].toString() !=
                "0x0000000000000000000000000000000000000000000000000000000000000000"
              ) {
                let temp = web3Map.utils.hexToAscii(result[0][i]).slice(0, 11);
                astarRoute.push(temp);
              }
            }
            astarRoute.reverse();
            console.log("astar: ", astarRoute);
            //add route point to map
            function draw2(p, q) {
              if (q == astarRoute.length) {
                return 1;
              }
              function doit2(geohash1, geohash2) {
                console.log("geohash1, geohash2: ", geohash1, geohash2);
                let route = L.polyline([geohash1, geohash2], {
                  color: "#00FF00",
                  fillColor: "#00FF00",
                  fillOpacity: 1,
                  weight: 7,
                });
                togetherLayers.push(route);
                // map.addLayer(route);
                // sleep(200);
              }
              setTimeout(doit2(astarRoute[p], astarRoute[q]), 0);
              draw2(p + 1, q + 1);
            }
            draw2(0, 1);
            this.togetherGroup = L.layerGroup(togetherLayers);
            map.addLayer(this.togetherGroup);
            //$("#Myevent").val("vehicle reached the end");
            console.log("执行了调度算法,车辆将乘客送到了终点");
            this.btnMsg = "等待乘客付款....";
          },
          function (err) {
            console.error("astarErr: ", err);
          }
        );
    },
    clear: function () {
      var map = global_.map;

      if (this.startPoint) map.removeLayer(this.startPoint);
      if (this.endPoint) map.removeLayer(this.endPoint);
      if (global_.userPoint) map.removeLayer(global_.userPoint);
      if (this.vehicleGroup) this.vehicleGroup.clearLayers();
      if (this.togetherGroup) this.togetherGroup.clearLayers();

      this.passengerId = "";
      this.passengerPlace="";
      this.passengerGeohash = "";
      this.endPlace = "";
      this.endGeohash="";

      this.isPickedUp = false;

      global_.userPoint = L.circle(global_.userGeohash, 20, {
        color: "#00FFAA",
      });
      global_.map.addLayer(global_.userPoint);
    },
  },
};
</script>
<style>
.dache-plan-root {
  position: absolute;
  height: 215px;
  bottom: 8px;
  right: 8px;
  left: 8px;
  padding-bottom: 10px;
  padding-top: 16px;
  background: #fff;
  z-index: 10;
  border-radius: 5px;
  -webkit-box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.15);
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.15);
  -webkit-box-sizing: border-box;
  box-sizing: border-box;
}
.partners-container {
  padding-top: 17px;
}
.partners-wrapper {
  height: 94px;
  overflow: hidden;
}
.partners,
.partner-item-c {
  display: -webkit-box;
  display: -ms-flexbox;
  display: flex;
  justify-content: center;
  overflow-x: scroll;
  -webkit-overflow-scrolling: touch;
  height: 100px;
}
.partner-item-c {
  flex-direction: column;
}
.partners .partner-item-c {
  margin-left: 8px;
  -ms-flex-negative: 0;
  flex-shrink: 0;
}
.partners .partner-item {
  position: relative;
  display: -webkit-box;
  display: -ms-flexbox;
  display: flex;
  -webkit-box-orient: vertical;
  -webkit-box-direction: normal;
  -ms-flex-direction: column;
  flex-direction: column;
  -webkit-box-align: center;
  -ms-flex-align: center;
  align-items: center;
  -webkit-box-pack: center;
  -ms-flex-pack: center;
  justify-content: center;
  width: 100%;
  height: 94px;
  padding: 15px;
  border-radius: 6px;
  font-size: 12px;
  color: #333;
  -webkit-box-sizing: border-box;
  box-sizing: border-box;
}
.btn-container {
  display: flex;
}
.button {
  margin: 15px 8px 0;
  padding: 10px 0;
  background: #3385ff;
  font-size: 16px;
  color: #fff;
  text-align: center;
  border-radius: 100px;
  width: 45%;
}
.button:checked {
  background: #102b55;
}
.nopickup {
  background: #ee9e09;
}
.Msg {
  width: 100%;
}
.partners .partner-item .partner-title .name,
.partners .partner-item {
  font-size: 12px;
}
.text-overflow {
  text-overflow: ellipsis;
  overflow: hidden;
  white-space: nowrap;
}
</style>