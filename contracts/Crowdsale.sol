pragma solidity ^0.4.18;

import "./ODYToken.sol";
import "./Ownable.sol";
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    
    // The token being sold
    ODYToken public token;

    // No-bonus price: 1 ether = 830 ODY
    uint public constant RATE = 830;

    // pre ico hard cap: 1,200,000 ODY
    uint256 public constant TOKEN_PRE_SALE_HARD_CAP = 1200000 ether;

    // main ico hard cap: 19,800,000 ODY
    uint256 public constant TOKEN_MAIN_SALE_HARD_CAP = 19800000 ether;

    // minium contribution value: 0.05 ether
    uint public constant MIN_VALUE = 0.05 ether;
    // maximum contribution value: 60 ehter
    uint public constant MAX_VALUE = 60 ether;

    uint8 public constant BONUS_STAGE1 = 50; // 50% bonus for pre ICO
    uint8 public constant BONUS_STAGE2 = 35; // 0-2000 ether 35%
    uint8 public constant BONUS_STAGE3 = 25; // 2000-4000 ether 25%
    uint8 public constant BONUS_STAGE4 = 20; // 4000-6000 ether 20%
    uint8 public constant BONUS_STAGE5 = 10; // 6000-14000 ether 10%

        // Date for pre ICO: April 15, 2018 12:00 pm UTC to May 15, 2018 12:00 pm UTC
    uint PRE_SALE_START = 1518574856; // 1523793600;
    uint PRE_SALE_END = 1526385600;

    // Date for main ICO: June 15, 2018 12:00 pm UTC to July 15, 2018 12:00 pm UTC
    uint MAIN_SALE_START = 1529064000;
    uint MAIN_SALE_END = 1531656000;

    // Maximum goals of the presale
    uint256 public constant PRE_SALE_MAXIMUM_FUNDING = 964 ether;
    
    // minimum goals of main sale
    uint256 public constant MINIMUM_FUNDING = 600 ether;
    // Maximum goals of main sale
    uint256 public constant MAXIMUM_FUNDING = 22420 ether;

    // The owner of this address is the Team fund
    address public teamFundAddress;

    uint8 public teamFundReleaseIndex;

    // team vest amount for every 6 months 375,000 ODY
    uint256 public constant TEAM_FUND_RELEASE_AMOUNT = 375000 ether;

    // The owner of this address is the Marketing fund
    address public marketingFundAddress;

    // The owner of this address is the Bounty fund
    address public bountyFundAddress;

    // The owner of this address is the Reserve fund
    address public reserveFundAddress;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of purchased token
    uint256 public tokenSold;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, uint value, uint amount);

    function Crowdsale(
        address _wallet,
        address _teamFundAddress,
        address _marketingFundAddress,
        address _bountyFundAddress,
        address _reserveFundAddress) public
        {
        require(_wallet != address(0));
        require(_teamFundAddress != address(0));
        require(_marketingFundAddress != address(0));
        require(_bountyFundAddress != address(0));
        require(_reserveFundAddress != address(0));

        token = createTokenContract();

        wallet = _wallet;
        teamFundAddress = _teamFundAddress;
        marketingFundAddress = _marketingFundAddress;
        bountyFundAddress = _bountyFundAddress;
        reserveFundAddress = _reserveFundAddress;

        // // Emission 40,000,000

        // 3,000,000 ODY are for marketing
        token.mint(marketingFundAddress, 3000000 ether);
        
        // 1,000,000 ODY are for Bounty
        token.mint(bountyFundAddress, 1000000 ether);

        // 12,000,000 ODY are reserved
        token.mint(reserveFundAddress, 12000000 ether);

        // pre sale ico + main sale ico + team fund
        token.mint(this, TOKEN_PRE_SALE_HARD_CAP + TOKEN_MAIN_SALE_HARD_CAP + 3000000 ether);
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (ODYToken) {
        return new ODYToken();
    }

    // @return if pre sale is in progress
    function isPreSale() internal view returns(bool) {
        return (now >= PRE_SALE_START && now <= PRE_SALE_END);
    }

    // @return if main sale is in progress
    function isMainSale() internal view returns(bool) {
        return (now >= MAIN_SALE_START && now <= MAIN_SALE_END);
    }

    // buy tokens from contract by sending ether
    function () public payable {
        // only accept a minimum amount of ETH?
        require(msg.value >= MIN_VALUE && msg.value <= MAX_VALUE);

        uint tokens = getTokenAmount(msg.value);

        require(validPurchase(msg.value, tokens));
        
        token.transfer(msg.sender, tokens);

        tokenSold += tokens;
        weiRaised += msg.value;

        TokenPurchase(msg.sender, msg.value, tokens);
        forwardFunds();
    }

    function validPurchase(uint weiAmount, uint tokenAmount) internal view returns(bool) {
        uint256 weiCap = weiRaised + weiAmount;
        uint256 cap = tokenSold + tokenAmount;
        
        bool preSaleValid = isPreSale() && cap <= TOKEN_PRE_SALE_HARD_CAP && weiCap <= PRE_SALE_MAXIMUM_FUNDING;
        bool mainSaleValid = isMainSale() && cap <= TOKEN_MAIN_SALE_HARD_CAP && weiCap <= MAXIMUM_FUNDING;

        return preSaleValid || mainSaleValid;
    }

    // calculate token amount for wei
    function getTokenAmount(uint weiAmount) internal view returns(uint) {
        uint tokens = weiAmount * RATE;
        uint bonus;

        // calculate bonus amount
        if (isPreSale()) {
            // 50% for pre ICO
            bonus = tokens * BONUS_STAGE1 / 100;
        } else {
            if (weiRaised <= 2000 ether)
                bonus = tokens * BONUS_STAGE2 / 100;
            else if (weiRaised <= 4000 ether)
                bonus = tokens * BONUS_STAGE3 / 100;
            else if (weiRaised <= 6000 ether) 
                bonus = tokens * BONUS_STAGE4 / 100;
            else if (weiRaised <= 14000 ether)
                bonus = tokens * BONUS_STAGE5 / 100;
        }

        return tokens + bonus;
    }

    // allocate token manually
    function allocate(address _address, uint _amount) public onlyOwner returns (bool success) {
        return token.transfer(_address, _amount);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function release() onlyOwner public {
        uint nextReleaseTime = MAIN_SALE_START + (teamFundReleaseIndex * 180 days);
        require(now >= nextReleaseTime && teamFundReleaseIndex < 8);
        token.transfer(teamFundAddress, TEAM_FUND_RELEASE_AMOUNT);
        teamFundReleaseIndex++;
    }

    /**
    * @dev Transfers the current balance to the owner and terminates the contract.
    */
    function destroy() onlyOwner public {
        token.destroy();
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        token.destroyAndSend(_recipient);
        selfdestruct(_recipient);
    }
}