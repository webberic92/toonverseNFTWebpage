// SPDX-License-Identifier: MIT
//  .----------------.  .----------------.  .----------------.  .-----------------. .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  _________   | || |     ____     | || |     ____     | || | ____  _____  | || | ____   ____  | || |  _________   | || |  _______     | || |    _______   | || |  _________   | |
// | | |  _   _  |  | || |   .'    `.   | || |   .'    `.   | || ||_   \|_   _| | || ||_  _| |_  _| | || | |_   ___  |  | || | |_   __ \    | || |   /  ___  |  | || | |_   ___  |  | |
// | | |_/ | | \_|  | || |  /  .--.  \  | || |  /  .--.  \  | || |  |   \ | |   | || |  \ \   / /   | || |   | |_  \_|  | || |   | |__) |   | || |  |  (__ \_|  | || |   | |_  \_|  | |
// | |     | |      | || |  | |    | |  | || |  | |    | |  | || |  | |\ \| |   | || |   \ \ / /    | || |   |  _|  _   | || |   |  __ /    | || |   '.___`-.   | || |   |  _|  _   | |
// | |    _| |_     | || |  \  `--'  /  | || |  \  `--'  /  | || | _| |_\   |_  | || |    \ ' /     | || |  _| |___/ |  | || |  _| |  \ \_  | || |  |`\____) |  | || |  _| |___/ |  | |
// | |   |_____|    | || |   `.____.'   | || |   `.____.'   | || ||_____|\____| | || |     \_/      | || | |_________|  | || | |____| |___| | || |  |_______.'  | || | |_________|  | |
// | |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
//2022 - © Toonverse - All Rights Reserved
//https://toonverse.net/


    pragma solidity^0.8.11;

    import "./ERC721A.sol";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol";


    contract TOONVERSE is ERC721A {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.06 ether;
    uint256 public maxSupply = 6666;
    uint256 public  immutable maxMintAmount = 5;
    bool public paused = true;
    bool public revealed = false;
    string public notRevealedUri;
    address public owner = msg.sender;
    bytes32 public whiteListMerkleRoot = 0xd4e5bd371dfbeece6f828705d5ba966c3f742b6f4429e7cf08f1b2248f7349a8;
    mapping(address => bool) public whiteListClaimed;
    bool public whiteListOnly = true;


    constructor() ERC721A("Toonverse", "TOON",maxSupply,maxMintAmount) {
        baseURI = "https://ethereyez.s3.amazonaws.com/";
        notRevealedUri = "https://ethereyez.s3.amazonaws.com/preReveal.json";

    }


        modifier onlyOwner() {
            require(msg.sender == owner, 'Only Owner');
            _;
        }

        modifier mintChecks(uint256 _mintAmount) {
        require(_mintAmount > 0, "Mint amount has to be greater than 0.");
        require(totalSupply() + _mintAmount <= maxSupply, "Minting that many would go over whats available.");
            _;
        }

    function setWhiteListMerkleRoot(bytes32 _wl) public onlyOwner {
            whiteListMerkleRoot = _wl;
        }

    function setWhiteListOnly(bool _b) public onlyOwner {
            whiteListOnly = _b;
        }
    

    function checkIfPaused() internal view {
        require(!paused,"Contract currently paused.");
    }


    function mint(uint256 _mintAmount) public payable  mintChecks(_mintAmount) {
        if (msg.sender != owner) {
            checkIfPaused();
            require(_mintAmount<= maxMintAmount, "Can not exceed max mint amount.");
            require(!whiteListOnly,"Only whitelist can mint right now.");
            require(msg.value >= cost * _mintAmount, "Not Enough Eth Sent.");
        }
        _safeMint(msg.sender,_mintAmount);

    }


    function mintWhiteList(bytes32[] calldata _merkleProof,uint256 _mintAmount) public payable  mintChecks(_mintAmount) {

        if(owner!=msg.sender){
            checkIfPaused();
            require(_mintAmount<= maxMintAmount, "Can not exceed max mint amount.");
            require(whiteListOnly,"Whitelist no longer available.");   
            require(!whiteListClaimed[msg.sender],"Address has already claimed");

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof,whiteListMerkleRoot,leaf),"Invalid Proof");
            require(msg.value >= cost * _mintAmount, "Not Enough Eth Sent.");

            }
        _safeMint(msg.sender,_mintAmount);
        whiteListClaimed[msg.sender]=true;


    }



    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, (_tokenId).toString(), baseExtension))
            : "";
    }

    function setRevealed(bool _b) public onlyOwner {
        revealed = _b;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function withdraw(uint256 _amount) public payable onlyOwner {
        
        (bool os, ) = payable(owner).call{value: _amount}("");
        require(os);
    }

  
    }
