// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PremiumPack is ERC1155, Ownable, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenCounter;

    event NewPackMinted(address receiver, uint256 tokenId, uint8 packType);
    event AirdroppedPackMinted(
        address sender,
        address receiver,
        uint256 tokenId,
        uint8 packType
    );

    mapping(address => bool) private whitelistClaimed;
    mapping(uint256 => uint8) public tokenPackType;
    mapping(uint256 => address) public airdropAddressList;

    struct Pack {
        uint256 price;
        uint8 packType;
        uint8 count;
    }

    Pack apprentice;
    Pack disciple;
    Pack primus;

    uint256 private mintAmount = 1;
    bytes private mintData = "";

    address private signer;

    address private withdrawalAddress;

    string public constant name = "Arkhante Booster Premium Pack Test";
    string public constant symbol = "CTAPRM";

    mapping(address => address) private signatures;

    bool public saleOpen = false;

    uint256 public constant maxSupply = 18638;

    uint256 private constant AIRDROP_NUMBER = 638;

    constructor(address sig, address withdraw) ERC1155("") {
        require(sig != address(0));
        require(withdraw != address(0));

        signer = sig;
        withdrawalAddress = withdraw;

        apprentice = Pack(61, 0, 0);
        disciple = Pack(153, 1, 0);
        primus = Pack(304, 2, 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    fallback() external payable {}

    receive() external payable {}

    function getPackByPackType(uint8 packType)
        private
        view
        returns (Pack memory pack)
    {
        require(packType < 3, "Invalid package type");

        if (packType == 0) {
            return apprentice;
        }
        if (packType == 1) {
            return disciple;
        }
        if (packType == 2) {
            return primus;
        }
    }

    function totalSupply() external pure returns (uint256) {
        return maxSupply;
    }

    function create(uint8 packType, bytes memory signature)
        public
        payable
        nonReentrant
    {
        Pack memory pack = getPackByPackType(packType);

        require(_tokenCounter.current() < maxSupply, "Max supply reached!");

        require(!whitelistClaimed[msg.sender], "Address has already minted!");

        require(saleOpen == true, "Sale is not open yet!");

        require(msg.value >= pack.price, "Matic value sent is not correct");

        processSignature(signer, msg.sender, signature);

        uint256 newTokenId = _tokenCounter.current();

        tokenPackType[newTokenId] = pack.packType;

        whitelistClaimed[msg.sender] = true;

        pack.count++;

        _tokenCounter.increment();

        _mint(msg.sender, newTokenId, mintAmount, mintData);

        emit NewPackMinted(msg.sender, newTokenId, packType);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenPackType[tokenId] <= 2, "Invalid package type");

        string memory id = Strings.toString(tokenPackType[tokenId]);

        return (
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/QmNt2QuqjD9CoW9dyvmEZkkBndW8AGj3NWse15zdtdTW4W/",
                    id,
                    ".json"
                )
            )
        );
    }

    function changePrice(uint256[] memory packType, uint256[] memory newPrice)
        public
        onlyOwner
    {
        require(saleOpen == false, "sale is not open now!");
        require(
            packType.length == newPrice.length,
            "newPrice length must be equal to packType length"
        );
        for (uint256 i = 0; i < packType.length; i++) {
            if (packType[i] == 0) {
                apprentice.price = newPrice[i];
            }
            if (packType[i] == 1) {
                disciple.price = newPrice[i];
            }
            if (packType[i] == 2) {
                primus.price = newPrice[i];
            }
        }
    }

    function changeSaleOpen(bool toggleSale) public onlyOwner {
        saleOpen = toggleSale;
    }

    function withDraw() public payable onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance on contract!");
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function setSigner(address sig) public onlyOwner {
        require(sig != address(0));
        signer = sig;
    }

    function processSignature(
        address account,
        address to,
        bytes memory signature
    ) private {
        if (hasSignature(to)) {
            return;
        }
        require(
            account == recoverAddress(fromMessage(account, to), signature),
            "Invalid signature provided"
        );
        signatures[to] = account;
    }

    function hasSignature(address sender) public view returns (bool) {
        return signatures[sender] != address(0);
    }

    function getSigner(address signee) public view onlyOwner returns (address) {
        require(signee != address(0));
        return signatures[signee];
    }

    function fromMessage(address from, address to)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(from, to));
    }

    function getSigner(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid signature 's' value"
        );
        require(v == 27 || v == 28, "invalid signature 'v' value");
        address signerMsg = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            ),
            v,
            r,
            s
        );
        require(signerMsg != address(0), "invalid signature");

        return signerMsg;
    }

    function recoverAddress(bytes32 message, bytes memory signature)
        private
        pure
        returns (address)
    {
        if (signature.length != 65) {
            revert("invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return getSigner(message, v, r, s);
    }

    function airdrop(
        uint8 packType,
        address toAirdropAddress,
        uint256 tokenId
    ) public onlyOwner {
        Pack memory pack = getPackByPackType(packType);

        require(toAirdropAddress != address(0));

        require(tokenId <= AIRDROP_NUMBER, "Max supply reached!");

        require(airdropAddressList[tokenId] == address(0));

        tokenPackType[tokenId] = pack.packType;

        airdropAddressList[tokenId] = toAirdropAddress;

        pack.count++;

        _tokenCounter.increment();

        _mint(toAirdropAddress, tokenId, mintAmount, mintData);

        emit AirdroppedPackMinted(
            msg.sender,
            toAirdropAddress,
            tokenId,
            packType
        );
    }
}