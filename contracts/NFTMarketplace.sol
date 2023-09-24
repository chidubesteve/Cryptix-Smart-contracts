// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// IMPORTS
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _ItemsSold;

    uint256 listingPrice = 0.0015 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private MarketItemId;

    // struct to define what the props or shape of waht each id will map to
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemIdCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only NFT owner can change the listing price"
        );
        _;
    }

    constructor() ERC721("Cryptix Metaverse Token", "CMETT") {
        owner == payable(msg.sender);
    }

    // this function is used tp set the price for the NFT's and to update it =>  but shoul dbe only called by the owner of the NFT
    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Mints a token(NFT) and lists it in the marketplace */
    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Creates a new tokenId, assigns it to newTokenId and mints it to who calls the function
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1");
        require(
            msg.value == listingPrice,
            "price must be equal to listing price"
        );

        MarketItemId[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemIdCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    // function to resale token(NFT) they've purchased
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(
            MarketItemId[tokenId].owner == msg.sender,
            "Only NFT owner can perform this action"
        );
        require(
            msg.value == listingPrice,
            "price must be equal to listing price"
        );

        MarketItemId[tokenId].sold = false;
        MarketItemId[tokenId].price = price;
        MarketItemId[tokenId].seller = payable(msg.sender);
        MarketItemId[tokenId].owner = payable(address(this));

        _ItemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    // function to buy NFT

    function purchaseNFT(uint256 tokenId) public payable {
        uint256 price = MarketItemId[tokenId].price;

        require(
            msg.value == price,
            "Please pay the amount specified on the NFT"
        );

        MarketItemId[tokenId].owner = payable(msg.sender);
        MarketItemId[tokenId].sold = true;
        MarketItemId[tokenId].seller = payable(address(0));
        _ItemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(MarketItemId[tokenId].seller).transfer(msg.value);
    }

    // getting unsold NFT in the marketplace
    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _ItemsSold.current();

        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (MarketItemId[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = MarketItemId[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // function to display all the NFT bought by someone on their profile

    function fetchMyNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (MarketItemId[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory myNfts = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (MarketItemId[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = MarketItemId[currentId];
                myNfts[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return myNfts;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (MarketItemId[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (MarketItemId[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = MarketItemId[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
