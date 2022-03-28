<script>
/*  全局变量组件
变量：用户信息、司机信息、合约示例、地图实例
方法：initContract初始化合约实例、initData初始化相关数据
*/
import Web3 from "../../node_modules/web3/lib/index.js";
import {
  mapContractAddress,
  mapContractAbi,
} from "../../static/js/mapContract.js";
import {
  trafficContractAddress,
  trafficContractAbi,
} from "../../static/js/trafficContract.js";
import jointPoints from "../../static/js/joint_points.js";
//Map contract
var mapContract;
var web3Map;
//Traffic contract
var trafficContract;
var web3Traffic;

//map conponent
var map;

//event
var geoToPalceMap = new Map();
var startPlace = "";
var dstPlace= "";
var startGeohash="";
var dstGeohash="";
var startPoint=null;
var dstPoint=null;
var placeNames = [];
var userID="0x9527fc82e8a9459b7008daf3403c37e267b53b11";
var userGeohash="wx4enz9fy7cp";
var userPoint=null;
var nearestPoint=null;
var vehicleID="";
var vehicleGeohash="";
//Contract Init
function initContract(mapContract, web3Map, trafficContract, web3Traffic) {
  console.log(">>>init contracts...");
  if (typeof web3 !== "undefined") {
    this.web3Map = new Web3(web3.currentProvider);
    this.web3Traffic = new Web3(web3.currentProvider);
  } else {
    this.web3Map = new Web3(
      new Web3.providers.WebsocketProvider("ws://127.0.0.1:8546")
    );
    this.web3Traffic = new Web3(
      new Web3.providers.WebsocketProvider("ws://127.0.0.1:8546")
    );
  }
  this.mapContract = new this.web3Map.eth.Contract(
    mapContractAbi,
    mapContractAddress
  );
  this.trafficContract = new this.web3Traffic.eth.Contract(
    trafficContractAbi,
    trafficContractAddress
  );
 console.log("mapContract", this.mapContract);
  console.log("trafficContract",this. trafficContract);
  console.log("OK!");
}
function initData(placeNames) {
  console.log(">>>>init data....");
  jointPoints.forEach((item) => {

    geoToPalceMap.set(item[0], item[1]);
  });
  var geohashToPalceMapItr = geoToPalceMap.values();
  for (let i = 0; i < geoToPalceMap.size; i++) {
    this.placeNames.push(geohashToPalceMapItr.next().value);
  }
}

export default {
  mapContract,
  web3Map,
  trafficContract,
  web3Traffic,
  map,
  startPlace,
  dstPlace,
   startGeohash,
   dstGeohash,
   startPoint,
   dstPoint,
  geoToPalceMap,
  placeNames,
  initContract,
  initData,
  userID,
  userGeohash,
  userPoint,
  nearestPoint,
  vehicleID,
  vehicleGeohash
};
</script>