//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC404 } from "./ERC404.sol";

contract NikolaErc404 is ERC404 {
    string public dataURI;
    string public baseTokenURI;
    string public metaDescription;

    constructor(address _owner)
        ERC404("Nikola SemiFungibles Rewards", "NIKOLA", 18, 10000, _owner)
    {
        balanceOf[_owner] = 10000 * 10**18;
        whitelist[_owner] = true;
    }

    function setDataURI(string memory _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setNameSymbol(string memory _name, string memory _symbol)
        public
        onlyOwner
    {
        _setNameSymbol(_name, _symbol);
    }

    function getNftImg(uint256 id) internal pure returns (string[2] memory) {
        uint8 idSeed = uint8(bytes1(keccak256(abi.encodePacked(id))));
        string memory image;
        string memory color;
        if (idSeed <= 100) {
            image = "1.jpg";
            color = "Retro Punk";
        } else if (idSeed <= 130) {
            image = "2.jpg";
            color = "Hybrid Cyborg";
        } else if (idSeed <= 160) {
            image = "3.jpg";
            color = "Ai Commander";
        } else if (idSeed <= 190) {
            image = "4.jpg";
            color = "Cyber Renegade";
        } else if (idSeed <= 220) {
            image = "5.jpg";
            color = "Web3 Evangelist";
        } else if (idSeed <= 255) {
            image = "6.jpg";
            color = "Future Humanoid";
        }
        return [image, color];
    }

    function setMetaDescription(string memory _metaDesc) public onlyOwner {
        metaDescription = _metaDesc;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (bytes(baseTokenURI).length > 0) {
            return string.concat(baseTokenURI, Strings.toString(id));
        } else {
            string memory image = getNftImg(id)[0];
            string memory color = getNftImg(id)[1];
            string memory nftMetaOpen = string.concat(
                string.concat(string.concat('{"name":''"', name, ' #',
                Strings.toString(id)),
                '","description":''"', metaDescription, '","external_url":"https://net2dev.io","image":"'),
                string.concat(dataURI, image));

            string memory nftMetaProperty = string.concat('","attributes":[{"trait_type":"Color","value":"',
                color
            );
            string memory nftMetaClose = '"}]}';
            return string.concat( "data:application/json;utf8,", string.concat(string.concat(nftMetaOpen, nftMetaProperty), nftMetaClose));
        }
    }
}