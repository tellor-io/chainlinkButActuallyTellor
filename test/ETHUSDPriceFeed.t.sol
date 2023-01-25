// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "../src/ETHUSDPriceFeed.sol";
import "../src/interfaces/AggregatorV3Interface.sol";
import "usingtellor/TellorPlayground.sol";

contract PriceConsumerV3Test is Test {
    TellorPlayground public tellor;
    TellorPlayground public token;
    ETHUSDPriceFeed public ethPriceFeed;
    AggregatorV3Interface public priceFeed;

    function setUp() public {
        tellor = new TellorPlayground();
        token = new TellorPlayground();

        ethPriceFeed = new ETHUSDPriceFeed(payable(address(tellor)));
        priceFeed = AggregatorV3Interface(address(ethPriceFeed));
    }
}
