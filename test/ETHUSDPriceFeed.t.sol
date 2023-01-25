// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "../src/ETHUSDPriceFeed.sol";
import "../src/interfaces/AggregatorV3Interface.sol";
import "usingtellor/TellorPlayground.sol";

contract PriceConsumerV3Test is Test {
    bytes queryData = abi.encode("SpotPrice", abi.encode("eth", "usd"));
    bytes32 ethUsdQueryId = keccak256(queryData);
    TellorPlayground public tellorOracle;
    ETHUSDPriceFeed public ethPriceFeed;
    AggregatorV3Interface public priceFeed;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        tellorOracle = new TellorPlayground();
        ethPriceFeed = new ETHUSDPriceFeed(payable(address(tellorOracle)));
        priceFeed = AggregatorV3Interface(address(ethPriceFeed));
    }

    function testGetLatestPrice() public {
        // submit fake price to tellor oracle, so it can be retrieved by ethPriceFeed
        vm.prank(alice);
        uint256 timestampWhenUpdated = block.timestamp;
        tellorOracle.submitValue(ethUsdQueryId, abi.encode(10000 * 10 ** 18), 0, queryData);

        vm.warp(block.timestamp + 1 * 3600 + 1); // advance time past one hour after last update

        // get latest price from ethPriceFeed
        vm.prank(bob);
        (, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();

        assertEq(answer, 10000 * 10 ** 18); // 10000 USD w/ 18 decimals of precision
        assertEq(updatedAt, timestampWhenUpdated);
    }
}
