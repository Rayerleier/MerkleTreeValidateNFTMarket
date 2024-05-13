pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {NFTmarket} from "../src/NFTMarket.sol";
import "../src/BaseERC20.sol";
import "../src/BaseERC721.sol";
import "./utils/SigUtils.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract NFTmarketTest is Test, Nonces {
    BaseERC20 erc20;
    BaseERC721 erc721;
    NFTmarket nftmarket;
    SigUtils internal sigutils;
    struct SignModal {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // bytes32[] memory proof = [
    //     bytes32(
    //         0x8888e6ff673c731be9a0ce96219cf1ac2b10667d5f704a6f13ffd9a28725d827
    //     ),
    //     bytes32(
    //         0x7371a814027976a7d8ae0178d0ac178d8d79718acbbd92e2f9159af39ef9c164
    //     ),
    //     bytes32(
    //         0x5cc21fee0f1bbb167bdf788eb4f919eecce52dfdf72c7b01d1ac6f67619515f7
    //     ),
    //     bytes32(
    //         0x5917d9bf70ab69c81a07a3651b73db49e2a73956a0a30a10962945253e5243cd
    //     ),
    //     bytes32(
    //         0xde97976f2386061528a99ff59df4f60b77c06ad548d396a2e6b33bbe16a9894b
    //     )
    // ];
    uint256 ownerPrivateKey = 12345;
    address nftowner_ = vm.addr(ownerPrivateKey);
    uint256 buyerPrivateKey = 78571927589;
    address buyer_ = vm.addr(buyerPrivateKey);
    address owner_ = makeAddr("owner");
    function setUp() public {
        vm.startPrank(nftowner_);
        nftmarket = new NFTmarket();
        erc721 = new BaseERC721("rain", "rayer", "arandomURI");
        erc721.setNFTMarket(address(nftmarket));
        erc20 = new BaseERC20("RAIN", "RAYER", 1e18);
        erc20.transfer(buyer_, 1e18);
        console.log("buyer_", buyer_);
        erc721.mint(nftowner_);
        erc721.approve(address(nftmarket), 1);
        sigutils = new SigUtils(erc20.DOMAIN_SEPARATOR());
    }

    function test_multicall() external {
        uint256 tokenId = 1;
        uint256 price = 1000;
        permitList(address(erc721), tokenId, price);

        bytes32[] memory proof = new bytes32[](5);
        proof[0] = bytes32(
            0x8888e6ff673c731be9a0ce96219cf1ac2b10667d5f704a6f13ffd9a28725d827
        );
        proof[1] = bytes32(
            0x7371a814027976a7d8ae0178d0ac178d8d79718acbbd92e2f9159af39ef9c164
        );
        proof[2] = bytes32(
            0x5cc21fee0f1bbb167bdf788eb4f919eecce52dfdf72c7b01d1ac6f67619515f7
        );
        proof[3] = bytes32(
            0x5917d9bf70ab69c81a07a3651b73db49e2a73956a0a30a10962945253e5243cd
        );
        proof[4] = bytes32(
            0xde97976f2386061528a99ff59df4f60b77c06ad548d396a2e6b33bbe16a9894b
        );
        vm.startPrank(buyer_);

        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: buyer_,
            spender: address(nftmarket),
            value: 100 * 1e18,
            nonce: erc20.nonces(buyer_),
            deadline: 1 days
        });
        bytes32 digest = sigutils.getTypedDataHash(
            permit.owner,
            permit.spender,
            permit.value,
            permit.nonce,
            permit.deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, digest);
        vm.stopPrank();
        vm.startPrank(buyer_);

        bytes memory callPrePay = buildCallPrePay(
            address(erc20),
            permit.owner,
            permit.spender,
            permit.value,
            permit.nonce,
            permit.deadline,
            v,
            r,
            s
        );
        bytes memory calllClaimNFT = buildCallClaimNFT(
            buyer_,
            address(erc721),
            address(erc20),
            tokenId,
            proof
        );
        bytes[] memory data = new bytes[](2);
        data[0] = callPrePay;
        data[1] = calllClaimNFT;
        multiCall(data);
    }

    function multiCall(bytes[] memory data) internal {
        nftmarket.multiCall(data);
    }

    function buildCallClaimNFT(
        address buyer,
        address nftCA,
        address tokenCA,
        uint256 tokenId,
        bytes32[] memory _merkleProof
    ) internal returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "claimNFT(address,address,address,uint256,bytes32[])",
                buyer,
                nftCA,
                tokenCA,
                tokenId,
                _merkleProof
            );
    }
    function buildCallPrePay(
        address token_ca,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "permitPrePay(address,address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)",
                token_ca,
                owner,
                spender,
                value,
                nonce,
                deadline,
                v,
                r,
                s
            );
    }

    function test_permitList() public {
        uint256 tokenId = 1;
        uint256 price = 1000;
        permitList(address(erc721), tokenId, price);
        assertEq(
            nftmarket.sellerOfNFT(address(erc721), tokenId),
            nftowner_,
            "nft owner exception"
        );
        assertEq(erc721.ownerOf(tokenId), address(nftmarket));
    }

    function permitList(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) internal {
        SigUtils sigutils1 = new SigUtils(erc721.DOMAIN_SEPARATOR());
        vm.startPrank(nftowner_);
        address spender = address(nftmarket);
        uint256 value = tokenId;
        uint256 deadline = 1 days;
        bytes32 digest = sigutils1.getTypedDataHash(
            nftowner_,
            spender,
            value,
            tokenId,
            deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        nftmarket.permitList(nftAddress, tokenId, deadline, price, v, r, s);
    }
}
