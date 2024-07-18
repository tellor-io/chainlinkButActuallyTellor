// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "usingtellor/UsingTellor.sol";

contract ETHUSDPriceFeed is UsingTellor {
    bytes queryData = abi.encode("SpotPrice", abi.encode("eth", "usd"));
    bytes32 ethUsdQueryId = keccak256(queryData);
    uint256 readDelay; //be sure to use the contract optimistically to allow time for disputes (e.g. 1 hours)
    
    constructor(address payable _tellor, uint256 _readDelay) UsingTellor(_tellor) {
        readDelay = _readDelay;
    }

    function latestRoundData()
        public
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 _updatedAt;
        bytes memory _value;
        int256 price;
        (_value, _updatedAt) = getDataBefore(ethUsdQueryId, block.timestamp - readDelay);
        price = int256(abi.decode(_value, (uint256)));
        return (0, price, _updatedAt, _updatedAt, 0);
    }
}
