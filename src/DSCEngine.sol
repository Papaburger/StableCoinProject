// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DSCEngine
 * @author Ferdinando Menezes
 *
 * This system is designed to be minimal, and the tokens maintain value 1 token == $1 peg.
 * Properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algoritmically Stable
 *
 * It is similar to DAI if DAI had no Governance, no fees and only backed by wETH and wBTC.
 *
 * DSC System should always be "over collateralized", at no point should the value of all collateral <= the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for Minting and Redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is very loosely based on MakerDAO DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    /////////////////
    //// ERRORS ////
    ////////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    /////////////////////////
    //// STATE VARIABLES ////
    /////////////////////////
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DecentralizedStableCoin private immutable i_dsc;

    ////////////////
    //// EVENTS ////
    ////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////////
    //// Modifiers ///
    //////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address[0]) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    //////////////////
    //// Functions ///
    //////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // USD PRICE FEEDs
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ///////////////////////////
    //// External Functions ///
    ///////////////////////////
    function depositCollateralAndMintDsc() external {}

    /*
     * @notice follows CEI
     * @param tokenCollateralAddress - The address of the token to deposit as collateral.
     * @param amountCollateral - The amount of collateral to deposit.
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() {}

    function burnDsc() {}

    function mintDsc() {}

    function liquidate() {}

    function getHealthFactor() external view {}
}
