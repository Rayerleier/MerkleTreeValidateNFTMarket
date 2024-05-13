const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")

// List of 7 public Ethereum addresses
let addresses = [
    "0x36134b897B03b36B14bb152427401384C127Ee68",  // address(0)是我生成的buyer地址
    "0x09627a2DD5f54e97e4c974CdeF8ABA793d80Af45",
    "0xe249dfd432b37872c40c0511cc5a3ae13906f77a",
    "0x66C5D4889067556C42AC3FB883fEe70b118CebEe",
    "0x518948e6dAe180bBA4Fdb0F819481d44C317A861",
    "0x660A05d1F5dB47cA59F5398757ACc11cbcecD9d3",
    "0x9A06adc8627CAEbFDE76c537e18FC1C1667b3b94",
    "0x76Ba86810e82c4e62b50597e65b2Dbe07207Fc37",
    "0x88888886989146b8eFb6D09eE52d085674AaaaB3",
    "0x33C901956Aa770CEEFdCBb605883f47c5A48d83c",
    "0xa0466a82B961e85077d4a8DEBC35fbF6Cf18D464",
    "0xbc26f7e3a9ca4cf73fab3be7deeb51e0330d05b5",
    "0xC3b0FAafeB7a80D9E3Bfde134972026B61c1F127",
    "0x22271C6e574f36149907eb7753C07d0bEA7Ba98c",
    "0xaDBB884cBE72c934bf54B29430d73c5e844fFCCA",
    "0x57f00454FF7ba629F53Ce0521EeD59e14f46D446",
    "0x5376cE606c9A1e14aB6C4a2388Fd4B3C73C73DC7",
    "0x8E8e3D65c3F2B85781510998aCAb7fc0A3beEA5F",
    "0xeD922c25702CA34d2aB1a2A4CcF576a9D5922F07",
    "0x74b73FD5B6A4d5A1Bb63f713997A9CBb1dF54815",
    "0x1c2e4962F222A9ab2DAAa4aF91dA5eF19779FB0A"
]

// Hash addresses to get the leaves
let leaves = addresses.map(addr => keccak256(addr))

// Create tree
let merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true })
// Get root
let rootHash = merkleTree.getRoot().toString('hex')

// Pretty-print tree
console.log(merkleTree.toString())
console.log("rootHash", rootHash)
// 'Serverside' code
let address = addresses[0]
let hashedAddress = keccak256(address)
let proof = merkleTree.getHexProof(hashedAddress)
console.log("proof",proof)

// Check proof
let v = merkleTree.verify(proof, hashedAddress, rootHash)
console.log(v) // returns true

