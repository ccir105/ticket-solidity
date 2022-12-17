// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Base64.sol";

contract TicketEvents is ERC721, ERC721Enumerable, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum Genres {
        BLUES,
        CLASSICAL,
        DEEP_HOUSE,
        DISCO
    }

    enum Gender {
        MALE,
        FEMALE,
        BOTH
    }

    struct Event {
        uint256 maxTickets;
        uint256 startAt;
        uint256 validity; //time length like 2 days where the event will be valid
        string venue;
        string location;
        string description;
        string lineup;
        Genres genre;
        Gender gender;
        uint8 age;
        string banner;
    }

    Event theEvent;

    mapping(uint256 => Event) allEvents;

    using SafeMath for uint256;
    using Strings for uint256;

    constructor(string memory name, Event memory ev) ERC721(name, "TICKET") {
        _setDefaultRoyalty(msg.sender, 500);
        theEvent = ev;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _getSingleAttribute(string memory name, string memory value) private pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type":"', name, '","value":"', value, '"}');
    }

    function _getGenre(Genres _genre) private pure returns (string memory) {
        string[] memory _genres = new string[](4);

        _genres[0] = "BLUES";
        _genres[1] = "CLASSICAL";
        _genres[2] = "DEEP_HOUSE";
        _genres[3] = "DISCO";

        return _genres[uint8(_genre)];
    }

    function _getGender(Gender _gender) private pure returns (string memory) {
        string[] memory _genders = new string[](3);

        _genders[0] = "MALE";
        _genders[1] = "FEMALE";
        _genders[2] = "BOTH";

        return _genders[uint8(_gender)];
    }

    function _buildAttributes() private view returns (bytes memory) {
        bytes memory result = abi.encodePacked(_getSingleAttribute("tokenId", theEvent.startAt.toString()), ",");
        result = abi.encodePacked(_getSingleAttribute("startAt", theEvent.startAt.toString()), ",");
        result = abi.encodePacked(result, _getSingleAttribute("location", theEvent.location), ",");
        result = abi.encodePacked(result, _getSingleAttribute("validity", theEvent.validity.toString()), ",");
        result = abi.encodePacked(result, _getSingleAttribute("venue", theEvent.venue), ",");
        result = abi.encodePacked(result, _getSingleAttribute("lineup", theEvent.lineup), ",");
        result = abi.encodePacked(result, _getSingleAttribute("genre", _getGenre(theEvent.genre)), ",");
        result = abi.encodePacked(result, _getSingleAttribute("gender", _getGender(theEvent.gender)), ",");
        result = abi.encodePacked(result, _getSingleAttribute("banner", theEvent.banner), ",");
        result = abi.encodePacked(result, _getSingleAttribute("age", uint256(theEvent.age).toString()));
        return result;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes memory attributes = _buildAttributes();

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        name(),
                        "#",
                        tokenId.toString(),
                        '",',
                        '"description":"',
                        theEvent.description,
                        '",',
                        '"attributes":[',
                        attributes,
                        "]}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function maxSupply() public view returns (uint256) {
        return theEvent.maxTickets;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function buyTicket() external {
        require(block.timestamp < theEvent.startAt);
        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawEth() public onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }
}
