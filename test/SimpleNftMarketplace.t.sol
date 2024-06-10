// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SimpleNftMarketplace.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleNftMarketplaceTest is Test {
    SimpleNftMarketplace marketplace;
    MockERC20 token;
    MockERC721 nft;
    address owner;
    address nftOwner;
    address user;

    function setUp() public {
        owner = address(0xb007);
        nftOwner = address(0xb0b);
        user = address(0xa11ce);
        vm.deal(nftOwner, 100 ether);
        vm.deal(user, 100 ether);

        vm.startPrank(nftOwner);
        token = new MockERC20();
        nft = new MockERC721();
        vm.stopPrank();

        vm.startPrank(owner);
        marketplace = new SimpleNftMarketplace();
        marketplace.initialize(owner);
        marketplace.setAllowedToken(address(token), true);
        vm.stopPrank();
    }

    function testSetAllowedToken() public {
        vm.startPrank(owner);
        marketplace.setAllowedToken(address(token), true);
        assertTrue(marketplace.allowedTokens(address(token)));
        vm.stopPrank();
    }

    function testCreateOffer() public {
        vm.startPrank(nftOwner);
        nft.mint(nftOwner, 1);
        nft.approve(address(marketplace), 1);

        marketplace.createOffer(address(nft), 1, 1 ether, address(0));
        (address seller,, uint256 tokenId,,,) = marketplace.offers(0);

        assertEq(seller, nftOwner);
        assertEq(tokenId, 1);
        vm.stopPrank();
    }

    function testCancelOffer() public {
        vm.startPrank(nftOwner);
        nft.mint(nftOwner, 1);
        nft.approve(address(marketplace), 1);

        marketplace.createOffer(address(nft), 1, 1 ether, address(0));
        marketplace.cancelOffer(0);

        (,,,,, bool isActive) = marketplace.offers(0);
        assertFalse(isActive);
        vm.stopPrank();
    }

    function testAcceptOfferWithETH() public {
        vm.startPrank(nftOwner);
        nft.mint(nftOwner, 1);
        nft.approve(address(marketplace), 1);
        marketplace.createOffer(address(nft), 1, 1 ether, address(0));
        vm.stopPrank();

        vm.startPrank(user);
        marketplace.acceptOffer{value: 1 ether}(0);
        (,,,,, bool isActive)  = marketplace.offers(0);
        assertFalse(isActive);
        assertEq(nft.ownerOf(1), user);
        vm.stopPrank();
    }

    function testAcceptOfferWithERC20() public {
        vm.startPrank(nftOwner);
        nft.mint(nftOwner, 1);
        nft.approve(address(marketplace), 1);        
        marketplace.createOffer(address(nft), 1, 1000, address(token));
        vm.stopPrank();

        vm.startPrank(user);
        token.mint(user, 2000);
        token.approve(address(marketplace), 1000);
        marketplace.acceptOffer(0);
        (,,,,, bool isActive)  = marketplace.offers(0);
        assertFalse(isActive);
        assertEq(nft.ownerOf(1), user);
        assertEq(token.balanceOf(nftOwner), 900);
        vm.stopPrank();
    }
}

// Mock ERC20 Token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock ERC20", "MERC20") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock ERC721 Token for testing
contract MockERC721 is ERC721 {
    constructor() ERC721("Mock ERC721", "MERC721") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
