// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/Test.sol";

import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "./BaseERC20.sol";
import "./BaseERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/INFTMarket.sol";
// import "../lib/openzeppelin-contracts/contracts/utils/Multicall.sol";

//Write a simple NFT market contract, using your own issued Token to buy and sell NFTs. The functions include:

// list(): Implement the listing function, where the NFT holder can set a price
// (how many tokens are needed to purchase the NFT) and list the NFT on the NFT market.
// buyNFT(): Implement the purchase function for NFTs,
// where users transfer the specified token quantity and receive the corresponding NFT.
contract NFTmarket is INFTMarket {
    struct listOfNFTs {
        uint256 price;
        address seller;
    }
    BaseERC20 tokenContract;
    BaseERC721 nftContract;

    bytes32 public root =
        0xa3d63d90e9423c5e1df4b2401002eb29ff739999f29cbf9d4fc4169931bc2f22;
    // tokenId => ListOfNFTS
    mapping(address => mapping(uint256 => listOfNFTs)) public listings;

    constructor() {
        // tokenContract = new BaseERC20("rain", "rayer", 1e18);
        // nftContract = new BaseERC721("rain", "rayer", "uri");
    }
    function sellerOfNFT(
        address nftCA,
        uint256 tokenId
    ) public view returns (address) {
        return listings[nftCA][tokenId].seller;
    }
    function priceOfNFT(
        address nftCA,
        uint256 tokenId
    ) public view returns (uint256) {
        return listings[nftCA][tokenId].price;
    }

    function checkValidity(
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "Incorrect proof"
        );
        return true; // Or you can mint tokens here
    }

    function multiCall(bytes[] calldata data) public {
        for (uint i = 0; i < data.length; i++) {
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Delegatecall failed");
        }
    }

    function permitPrePay(
        address token_ca,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        BaseERC20(token_ca).permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
    }

    function claimNFT(
        address buyer,
        address nftCA,
        address tokenCA,
        uint256 tokenId,
        bytes32[] calldata _merkleProof
    ) public {
        uint256 price = priceOfNFT(nftCA, tokenId);
        address seller = sellerOfNFT(nftCA, tokenId);
        if (checkValidity(_merkleProof)) {
            price = (price * 50) / 100;
        }
        BaseERC20(tokenCA).transferFrom(buyer, seller, price);
        BaseERC721(nftCA).safeTransferFrom(address(this), buyer, tokenId);
        emit OrderListed(msg.sender, nftCA, tokenId, price);
    }
    function permitList(
        address _nftAddress,
        uint256 _tokenId,
        uint256 deadline,
        uint256 _price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        _permitList(_nftAddress, _tokenId, deadline, _price, v, r, s);
    }
    function _permitList(
        address _nftAddress,
        uint256 _tokenId,
        uint256 deadline,
        uint256 _price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        nftContract = BaseERC721(_nftAddress);
        nftContract.permit(
            msg.sender,
            address(this),
            _tokenId,
            deadline,
            v,
            r,
            s
        );
        list(_nftAddress, _tokenId, _price);
    }

    function list(address nftAddress, uint256 tokenId, uint256 price) public {
        nftContract = BaseERC721(nftAddress);
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "You are not the owner"
        );
        require(price > 0, "price must be greater than 0");
        listings[nftAddress][tokenId].seller = msg.sender;
        listings[nftAddress][tokenId].price = price;
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Listed(nftAddress, tokenId, msg.sender, price);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function buy(
        uint256 tokenId,
        address _tokenAdress,
        address _nftAdress
    ) public {
        tokenContract = BaseERC20(_tokenAdress);
        nftContract = BaseERC721(_nftAdress);
        listOfNFTs memory listing = listings[_nftAdress][tokenId];
        require(listing.price > 0, "this is not for sale");
        require(
            nftContract.ownerOf(tokenId) == address(this),
            "already selled"
        );
        tokenContract.transferFrom(msg.sender, listing.seller, listing.price);
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        delete listings[_nftAdress][tokenId];
        emit Bought(tokenId, msg.sender, listing.seller, listing.price);
    }
}
