// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

// import OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {

    // set owner
    address payable public owner;

    // keep track of token ids w/ openzeppelin
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // here's our Top Level Domain
    string public tld;

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><defs id="defs6"><clipPath id="clipPath18"><path d="M 0,38 38,38 38,0 0,0 0,38 z" id="path20"/></clipPath></defs><g transform="matrix(1.25,0,0,-1.25,0,47.5)" id="g12"><g id="g14"><g clip-path="url(#clipPath18)" id="g16"><g transform="translate(7,33)" id="g22"><path d="m 0,0 c 3,0 5,-2 8,-6 3,-4 7.957,-7.191 12,-8 5,-1 9,-5 9,-11 0,-4.897 -3.846,-7 -9,-7 -5,0 -9,3 -14,8 -5,5 -10,14 -10,18 0,4 1,6 4,6" id="path24" style="fill:#744eaa;fill-opacity:1;fill-rule:nonzero;stroke:none"/></g><g transform="translate(4.5146,37)" id="g26"><path d="m 0,0 c 1.248,0 1.248,-1.248 1.248,-2.495 0,-1.764 1.247,-1.129 2.495,-1.129 C 4.99,-3.624 7.485,-6 7.485,-6 l -3.742,0 c -1.248,0 0,-2.614 -1.248,-2.614 -1.247,0 -1.247,1.188 -2.495,1.188 -1.248,0 -1.515,-3.574 -1.515,-3.574 0,0 -1.604,4.153 0.267,6.024 C 0,-3.728 -2.495,0 0,0" id="path28" style="fill:#77b255;fill-opacity:1;fill-rule:nonzero;stroke:none"/></g></g></g></g><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="65" y="145" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';


    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint => string) public names;

    // errors
    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);

    // make contract payable
    constructor(string memory _tld) payable ERC721("Sexy Name Service", "SNS") {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    // function to limit length of domain name
    function valid(string calldata name) public pure returns(bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }

    // public view function to return all domain names
    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract:");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    // this gives us the price of domain based on length
    function price(string calldata name) public pure returns(uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17;
        } else if (len == 4) {
            return 3 * 10**17;
        } else {
            return 1 * 10**17;
        }
    }

    // register function that adds names to our mapping
    function register(string calldata name) public payable {
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        uint _price = price(name);
        require(msg.value >= _price, "Not enough MATIC paid");

        // combine name passed in function w/ the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // create the SVG for NFT w/ name
        string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

        // create JSON metadata for NFT
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Sexy name service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

        console.log("\n--------------------------------------------------------");
        console.log("Final tokenURI", finalTokenUri);
        console.log("--------------------------------------------------------\n");

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        names[newRecordId] = name;
        _tokenIds.increment();
    }

    // this gives us the domain owner's address
    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // check that the owner is the transaction sender
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns (string memory) {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }
}