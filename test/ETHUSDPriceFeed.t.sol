// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "../src/ETHUSDPriceFeed.sol";
import "../src/interfaces/AggregatorV3Interface.sol";
import "../src/SecretTellorUser.sol";
import "usingtellor/TellorPlayground.sol";

contract PriceConsumerV3Test is Test {
    bytes queryData = abi.encode("SpotPrice", abi.encode("eth", "usd"));
    bytes32 ethUsdQueryId = keccak256(queryData);
    TellorPlayground public tellorOracle;
    ETHUSDPriceFeed public ethPriceFeed;
    SecretTellorUser public userContract;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        tellorOracle = new TellorPlayground();
        ethPriceFeed = new ETHUSDPriceFeed(payable(address(tellorOracle)),1 hours);
        userContract = new SecretTellorUser(address(ethPriceFeed));
    }

    function testGetLatestPrice() public {
        // submit fake price to tellor oracle, so it can be retrieved by ethPriceFeed
        vm.prank(alice);
        uint256 timestampWhenUpdated = block.timestamp;

        tellorOracle.submitValue(ethUsdQueryId, abi.encode(10000 * 10 ** 18), 0, queryData);
        //assert no update if not an hour
                vm.warp(block.timestamp + 60);
        vm.warp(block.timestamp + 1 * 3600 + 1); // advance time past one hour after last update
        // get latest price from ethPriceFeed
        vm.prank(bob);
        (, int256 answer,, uint256 updatedAt,) = ethPriceFeed.latestRoundData();
        assertEq(answer, 10000 * 10 ** 18); // 10000 USD w/ 18 decimals of precision
        assertEq(updatedAt, timestampWhenUpdated);
        userContract.setEthPrice();
        assertEq(userContract.lastPrice(),10000 * 10 ** 18);
        assertEq(userContract.lastStoredTimestamp(),timestampWhenUpdated);
    }

    function testTooOld() public {
        vm.prank(alice);
        uint256 timestampWhenUpdated = block.timestamp;
        tellorOracle.submitValue(ethUsdQueryId, abi.encode(10000 * 10 ** 18), 0, queryData);
        vm.warp(block.timestamp + 1 * 3600 + 1); // advance time past one hour after last update
        // get latest price from ethPriceFeed
        vm.prank(bob);
        userContract.setEthPrice();
        uint256 timestampWhenUpdated2 = block.timestamp;
        tellorOracle.submitValue(ethUsdQueryId, abi.encode(2 * 10 ** 18), 0, queryData);
        vm.warp(block.timestamp + 24 * 3600 + 1); // advance time 24 hour after last update
        vm.prank(bob);
        (, int256 answer,, uint256 updatedAt,) = ethPriceFeed.latestRoundData();
        assertEq(answer, 2 * 10 ** 18); // 10000 USD w/ 18 decimals of precision
        assertEq(updatedAt, timestampWhenUpdated2);
        userContract.setEthPrice();
        assertEq(userContract.lastPrice(),10000 * 10 ** 18);
        assertEq(userContract.lastStoredTimestamp(),timestampWhenUpdated);
    }

    function testDisputeAttack() public {
            //test dispute time travel attack
        uint256 timestampWhenUpdated = block.timestamp;
        tellorOracle.submitValue(ethUsdQueryId, abi.encode(3 * 10 ** 18), 0, queryData);
        vm.warp(block.timestamp + 1);
        uint256 timestampWhenUpdated2 = block.timestamp;
        tellorOracle.submitValue(ethUsdQueryId, abi.encode(4 * 10 ** 18), 0, queryData);
        vm.warp(block.timestamp + 1 * 3600 + 1); // advance one hour after last update
        vm.prank(bob);
        (, int256 answer,, uint256 updatedAt,) = ethPriceFeed.latestRoundData();
        assertEq(answer, 4 * 10 ** 18); // 10000 USD w/ 18 decimals of precision
        assertEq(updatedAt, timestampWhenUpdated2);
        userContract.setEthPrice();
        assertEq(userContract.lastPrice(),4 * 10 ** 18);
        assertEq(userContract.lastStoredTimestamp(),timestampWhenUpdated2);
        tellorOracle.beginDispute(ethUsdQueryId,timestampWhenUpdated2);
        (, answer,, updatedAt,) = ethPriceFeed.latestRoundData();
        assertEq(answer, 3 * 10 ** 18); // 10000 USD w/ 18 decimals of precision
        assertEq(updatedAt, timestampWhenUpdated);
        //should not update here
        userContract.setEthPrice();
        assertEq(userContract.lastPrice(),4 * 10 ** 18);
        assertEq(userContract.lastStoredTimestamp(),timestampWhenUpdated2);
    }
}
