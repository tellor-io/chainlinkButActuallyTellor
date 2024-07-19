// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/AggregatorV3Interface.sol";

contract SecretTellorUser {
    AggregatorV3Interface public ethOracle;
    int256 public lastPrice;
    uint256 public lastStoredTimestamp; // Cache timestamp to prevent dispute attacks

    // Input tellor oracle address
    constructor(address _ethOracle) {
        ethOracle = AggregatorV3Interface(_ethOracle);
    }

    function setEthPrice()
        public
    {
        int256 _value;
        uint256 _timestampRetrieved;
        // Retrieve data at least 15 minutes old to allow time for disputes
        (,_value,_timestampRetrieved,,) = ethOracle.latestRoundData();
        // If timestampRetrieved is 0, no data was found
        if(_timestampRetrieved > 0) {
            // Check that the data is not too old
            if(block.timestamp - _timestampRetrieved < 24 hours) {
                // Check that the data is newer than the last stored data to avoid dispute attacks
                if(_timestampRetrieved > lastStoredTimestamp) {
                    lastStoredTimestamp = _timestampRetrieved;
                    lastPrice = _value;
                }
            }
        }
    }
}
