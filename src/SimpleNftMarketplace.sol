// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract SimpleNftMarketplace is Initializable, AccessControl, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    
    struct Offer {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address paymentToken; // Address(0) for ETH
        bool isActive;
    }

    uint256 public offerCount;
    mapping(uint256 => Offer) public offers;
    mapping(address => bool) public allowedTokens;

    event OfferCreated(uint256 offerId, address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price, address paymentToken);
    event OfferCancelled(uint256 offerId);
    event OfferAccepted(uint256 offerId, address indexed buyer);

    function initialize(address admin) initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(UPGRADER_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function setAllowedToken(address token, bool allowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokens[token] = allowed;
    }

    function createOffer(address nftContract, uint256 tokenId, uint256 price, address paymentToken) external {
        require(allowedTokens[paymentToken] || paymentToken == address(0), "Token not allowed");
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        offers[offerCount] = Offer({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            paymentToken: paymentToken,
            isActive: true
        });

        emit OfferCreated(offerCount, msg.sender, nftContract, tokenId, price, paymentToken);
        offerCount++;
    }

    function cancelOffer(uint256 offerId) external {
        Offer storage offer = offers[offerId];
        require(offer.isActive, "Offer not active");
        require(offer.seller == msg.sender, "Only seller can cancel");

        offer.isActive = false;
        IERC721(offer.nftContract).transferFrom(address(this), msg.sender, offer.tokenId);

        emit OfferCancelled(offerId);
    }

    function acceptOffer(uint256 offerId) external payable {
        Offer storage offer = offers[offerId];
        require(offer.isActive, "Offer not active");

        offer.isActive = false;

        uint256 fee = offer.price / 10;
        uint256 sellerAmount = offer.price - fee;

        if (offer.paymentToken == address(0)) {
            require(msg.value == offer.price, "Incorrect ETH amount");
            payable(offer.seller).transfer(sellerAmount);
            payable(getRoleMember(DEFAULT_ADMIN_ROLE, 0)).transfer(fee);
        } else {
            IERC20(offer.paymentToken).transferFrom(msg.sender, offer.seller, sellerAmount);
            IERC20(offer.paymentToken).transferFrom(msg.sender, getRoleMember(DEFAULT_ADMIN_ROLE, 0), fee);
        }

        IERC721(offer.nftContract).transferFrom(address(this), msg.sender, offer.tokenId);

        emit OfferAccepted(offerId, msg.sender);
    }
}
