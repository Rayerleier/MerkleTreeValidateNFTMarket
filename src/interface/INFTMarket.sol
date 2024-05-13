pragma solidity ^0.8.0;

interface INFTMarket {
    event OrderListed(
        address indexed from,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 listPrice
    );

    event OrderBought(
        address indexed from,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 listPrice
    );

    event Listed(
        address indexed nftca,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event Bought(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );
}
