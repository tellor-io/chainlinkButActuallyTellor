// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "usingtellor/UsingTellor.sol";


contract ETHUSDPriceFeed is UsingTellor {
    bytes queryData = abi.encode("SpotPrice", abi.encode("eth", "usd"));
    bytes32 ethUsdQueryId = keccak256(queryData);
    
    constructor(address payable _tellor) UsingTellor(_tellor) {}

    function latestRoundData() public view returns (
    //   uint80 roundId,
    //   int256 answer,
    //   uint256 startedAt,
    //   uint256 updatedAt,
    //   uint80 answeredInRound
        int256 answer,
        uint256 updatedAt
    )
    {
        uint256 _timestamp;
        bytes memory _value;
        (_value, _timestamp) = getDataBefore(ethUsdQueryId, block.timestamp - 1 hours);
        int256 price = int256(abi.decode(_value,(uint256)));
        return (price, _timestamp);
    }
}