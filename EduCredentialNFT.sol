// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Importing OpenZeppelin ERC721 NFT implementation
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Extension to allow storing token URIs on chain
import "@openzeppelin/contracts/access/AccessControl.sol"; // Role based access control system
import "@openzeppelin/contracts/security/Pausable.sol"; // Contract pausing functionality
import "@openzeppelin/contracts/utils/Counters.sol"; // Counter utility for token IDs

 // @title EduCredentialNFT
 // @dev A Soulbound NFT for educational credentials with role based minting and pausing.
 //      Soulbound = Non-transferable. Once issued, it stays permanently with the recipient.
 
contract EduCredentialNFT is ERC721, ERC721URIStorage, AccessControl, Pausable {

    using Counters for Counters.Counter; 
    Counters.Counter private _tokenId; // Tracks the incremental token IDs

    // Role identifiers hashed strings
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); 
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

     // @dev Constructor sets up token name, symbol, and assigns roles to deployer.
    constructor() ERC721("EduCredentialNFT", "ECNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Full admin rights
        _grantRole(MINTER_ROLE, msg.sender);        // Can mint NFTs
        _grantRole(PAUSER_ROLE, msg.sender);        // Can pause/unpause contract
    }

     // @dev Supports interface checks for multiple inherited contracts.
    function supportsInterface(bytes4 interfaceId) 
        public view virtual 
        override(ERC721, ERC721URIStorage, AccessControl) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

     // @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 tokenId) 
        public view 
        override (ERC721, ERC721URIStorage) 
        returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }

    //  Soulbound Restrictions
    // Override all transfer/approval functions to block transfers
    function transferFrom(address, address, uint256) 
        public pure override (ERC721, IERC721) 
    {
        revert("Soulbound: Transfer not allowed");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) 
        public pure override (ERC721, IERC721) 
    {
        revert("Soulbound: Transfer not allowed");
    }

    function approve(address, uint256) 
        public pure override (ERC721, IERC721) 
    {
        revert("Soulbound: Approval not allowed");
    }

    function setApprovalForAll(address, bool) 
        public pure override (ERC721, IERC721) 
    {
        revert("Soulbound: Approval not allowed");
    }

     // @dev Mint a single credential NFT to `to` with associated `uri`.
     //      Restricted to MINTER_ROLE and only when not paused.
    function mintCredential(address to, string memory uri) 
        public onlyRole(MINTER_ROLE) whenNotPaused 
    {
        _tokenId.increment(); // Increment token counter
        uint256 tokenId = _tokenId.current();
        _safeMint(to, tokenId); // Mint the NFT
        _setTokenURI(tokenId, uri); // Set the metadata URI
    }

    
     // @dev Mint multiple credential NFTs in a single transaction.
     //      Ensures `to` and `uris` arrays match in length.
    function batchMintCredentials(address[] memory to, string[] memory uris) 
        public onlyRole(MINTER_ROLE) whenNotPaused 
    {
        require(to.length == uris.length, "BatchMint: Length mismatch");
        for(uint256 i = 0; i < to.length; i++) {
            _tokenId.increment();
            uint256 tokenId = _tokenId.current();
            _safeMint(to[i], tokenId);
            _setTokenURI(tokenId, uris[i]);
        }
    }

     // @dev View credential metadata for a specific tokenId.
    function getCredential(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

     // @dev Pause minting and other restricted actions.
     //      Only accounts with PAUSER_ROLE can call.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

     // @dev Unpause the contract to resume minting
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

}