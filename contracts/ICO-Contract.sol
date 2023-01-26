// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title An ICO Contract that distributes the token among public if the preSale is active
 * buyers are divided into whitelist users & common public
 */
contract ICO is Ownable {
    /// @dev store the total supply of token in this variable
    uint256 public totalSupply;
    /// @dev store the start time of preSale in the variable
    uint256 public startTime;
    /// @dev store the wallet owner's address in this variable, this address will release funds
    address payable ownerWallet;

    /// @dev store the trade rate at which tokens will be given to whitelist & common users
    uint256 foundersProfitRate = 5;
    uint256 crowdSaleProfitRate = 2;

    /// @dev Pass the address of the token Contract you want to transfer tokens from
    IERC20 token;

    /// @dev this variable stores the total amount of funds collected by trading tokens
    uint256 public fundsRaised;

    /**
     * @notice this modifier only lets the buyers buy tokens when preSale is active
     */
    modifier preSaleActive() {
        require(block.timestamp < startTime + 5000, "PreSale is ended");
        _;
    }

    /// @notice notifies who invested how much
    event fundsRecieved(address investor, uint256 amount);
    /// @notice notifies if the investor has collected his profit or not
    event profitCollected(address investor, uint256 profitAmount);

    /** @dev Deploy the token contract before this one
     *@dev set wallet of `msg.sender` as the owner's wallet
     * @dev sets totalSupply of token from the user
     * @notice this will check if zero address is passed as the owner of the contract
     **/
    constructor(
        address payable _ownerWallet,
        IERC20 _token,
        uint256 _totalSupply
    ) {
        require(_ownerWallet != address(0));

        startTime = block.timestamp;
        ownerWallet = _ownerWallet;
        token = _token;
        totalSupply = _totalSupply;
    }


    /** @notice this will store the total number of available public tokens & tokens reserved for founders
     **/
    uint256 publicTokens;
    uint256 founderTokens;

    /**
     * @dev getTotalPublicTokens function returns the total number of tokens reserved for public
     */
    function getTotalPublicTokens() public returns (uint256) {
        publicTokens = (totalSupply / 100) * 75;
        return publicTokens;
    }

    uint256 max = getTotalPublicTokens();

    /**
     * @dev getTotalFounderTokens function returns the total number of tokens reserved for founders
     */
    function getTotalFounderTokens() public returns (uint256) {
        founderTokens = (totalSupply / 100) * 25;
        return founderTokens;
    }

    /**
     * @dev getAvailablePercentageOfFounderTokens function returns the total number of tokens reserved
     * for founders for the given time frame
     */
    function getAvailablePercentageOfFounderTokens() public returns (uint256) {
        uint256 developerTokens;

        if (block.timestamp <= startTime + 500) {
            developerTokens = (getTotalFounderTokens() / 100) * 20;  
        } else if (block.timestamp <= startTime + 1000) {
            developerTokens = (getTotalFounderTokens() / 100) * 40;
        } else {
            developerTokens = (getTotalFounderTokens() / 100) * 40;
        }
        return developerTokens;
    }

    /**
     * @dev getAvailablePercentageOfPublicTokens function returns the total number of tokens reserved for public
     * for the given time frame
     */
    function getAvailablePercentageOfPublicTokens() public returns (uint256) {
        uint256 commonTokens;

        if (block.timestamp <= startTime + 500) {
            commonTokens = (getTotalPublicTokens() / 100) * 20;
        } else if (block.timestamp < startTime + 1000) {
            commonTokens = (getTotalPublicTokens() / 100) * 40;
        } else {
            commonTokens = (getTotalPublicTokens() / 100) * 40;
        }
        return commonTokens;
    }

    /// funds invested by each investor are saved against their addresses
    mapping(address => uint256) fundsInvested;
    /// profit due for each investor is saved against their addresses
    mapping(address => uint256) profitDue;
    /// all the investor addresses are saved in this array
    address[] public whitelistInvesters;

    /**
     * @dev addWhitelistInvester function adds the whitelist user
     * @notice this function can only be called by the owner of this contract
     */
    function addWhitelistInvester(address investor) public onlyOwner {
        whitelistInvesters.push(investor);
    }

    /**
     * @dev invest function  adds the wlets the investor invest his funds in the ICO
     * @notice this function can only be called if the preSale is active
     * @notice before investing, this function checks if the invested amount is greater than zero
     * @notice this function seperately calculates the profit for whitelist admins & public investors
     */
    function invest(uint amount) public payable preSaleActive {
        require(amount > 0);
        fundsInvested[msg.sender] = amount;

        ownerWallet.transfer(amount);

        fundsRaised += amount;

        uint256 profit;

        for (uint256 i = 0; i < whitelistInvesters.length; i++) {
            if (whitelistInvesters[i] == msg.sender) {
                profit = amount * foundersProfitRate;
            } else {
                profit = amount * crowdSaleProfitRate;
            }
        }

        profitDue[msg.sender] = profit;
        emit fundsRecieved(msg.sender, amount);
    }

    /**
     * @dev collectProfit function lets the investor collect profit for the funds they invested
     * @notice this function checks if the msg.sender is even an investor or not
     * @notice before transferring the profit, it checks if the available supply of tokens for both(whitelist admins & public)
     * is exceeded or not
     */
    function collectProfit() public payable {
        require(fundsInvested[msg.sender] != 0, "You are not an investor");

        uint256 transferableTokens;
        for (uint256 i = 0; i < whitelistInvesters.length; i++) {
            if (whitelistInvesters[i] == msg.sender) {
                require(
                    profitDue[msg.sender] <=
                        getAvailablePercentageOfFounderTokens(),
                    "Not enough tokens left to award, Please wait for the next phase."
                );
                transferableTokens = profitDue[msg.sender];
                founderTokens -= transferableTokens;
            } else {
                require(
                    profitDue[msg.sender] <=
                        getAvailablePercentageOfPublicTokens(),
                    "Not enough tokens left to award, Please wait for the next phase."
                );
                transferableTokens = profitDue[msg.sender];
                publicTokens -= transferableTokens;
            }
        }

        token.transfer(msg.sender, transferableTokens);
        emit profitCollected(msg.sender, transferableTokens);
    }
}
