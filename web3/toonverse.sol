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

    uint256 public COST = 0.038 ether;
    uint256 public MAX_SUPPLY = 6666;
    uint256 public  immutable MAX_MINT_AMOUNT = 20;
    string public BASE_URI ="https://toonverse.s3.amazonaws.com/";
    string public BASE_EXTENSION = ".json";
    string public NOT_REVEALED_URI= "https://toonverse.s3.amazonaws.com/1.json";
    bool public PAUSED = true;
    bool public REVEALED = false;

    address public OWNER = msg.sender;
    address public DEV = 0x6aF9cE90BaA2640cc06f9661B37835Ab97807311;
    address public PARTNER =0x4bE40dFf0B2B77Aef1d3d783795900c89e6E8Fbf;
    bytes32 public WHITELIST_MERKLE_ROOT = 0xd4e5bd371dfbeece6f828705d5ba966c3f742b6f4429e7cf08f1b2248f7349a8;
    mapping(address => bool) public WHITELIST_CLAIMED;
    bool public IS_WHITELIST_ONLY = true;


    constructor() ERC721A("Toonverse", "TOON",MAX_SUPPLY,MAX_MINT_AMOUNT) {
        _safeMint(OWNER,100);
        _safeMint(PARTNER,50);
        _safeMint(DEV,25);
    }


        modifier onlyOwner() {
            require(msg.sender == OWNER, 'Only OWNER');
            _;
        }

        modifier onlyDev() {
            require(msg.sender == DEV, 'Only Dev');
            _;
        }

        modifier mintChecks(uint256 _mintAmount) {
        require(_mintAmount > 0, "Mint amount has to be greater than 0.");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Minting that many would go over whats available.");
            _;
        }

    function setWhiteListMerkleRoot(bytes32 _wl) public onlyOwner {
            WHITELIST_MERKLE_ROOT = _wl;
        }

    function setWhiteListOnly(bool _b) public onlyOwner {
            IS_WHITELIST_ONLY = _b;
        }
    

    function checkIfPaused() internal view {
        require(!PAUSED,"Contract currently PAUSED.");
    }


    function mint(uint256 _mintAmount) public payable  mintChecks(_mintAmount) {
        if (msg.sender != OWNER) {
            checkIfPaused();
            require(_mintAmount<= MAX_MINT_AMOUNT, "Can not exceed max mint amount.");
            require(!IS_WHITELIST_ONLY,"Only whitelist can mint right now.");
            require(msg.value >= COST * _mintAmount, "Not Enough Eth Sent.");
        }
        _safeMint(msg.sender,_mintAmount);

    }


    function mintWhiteList(bytes32[] calldata _merkleProof,uint256 _mintAmount) public payable  mintChecks(_mintAmount) {

        if(OWNER!=msg.sender){
            checkIfPaused();
            require(_mintAmount<= MAX_MINT_AMOUNT, "Can not exceed max mint amount.");
            require(IS_WHITELIST_ONLY,"Whitelist no longer available.");   
            require(!WHITELIST_CLAIMED[msg.sender],"Address has already claimed");

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof,WHITELIST_MERKLE_ROOT,leaf),"Invalid Proof");
            require(msg.value >= COST * _mintAmount, "Not Enough Eth Sent.");

            }
        _safeMint(msg.sender,_mintAmount);
        WHITELIST_CLAIMED[msg.sender]=true;


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
        
        if(REVEALED == false) {
            return NOT_REVEALED_URI;
        }

        return bytes(BASE_URI).length > 0
            ? string(abi.encodePacked(BASE_URI, (_tokenId).toString(), BASE_EXTENSION))
            : "";
    }

    function setRevealed(bool _b) public onlyOwner {
        REVEALED = _b;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        COST = _newCost;
    }

    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        NOT_REVEALED_URI = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        BASE_URI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        BASE_EXTENSION = _newBaseExtension;
    }

    function setPaused(bool _state) public onlyOwner {
        PAUSED = _state;
    }
    
    function setDev(address _address) public onlyDev {
        DEV = _address;
    }
    function withdraw(uint256 _amount) public payable onlyOwner {
        
        (bool os, ) = payable(OWNER).call{value: _amount}("");
        require(os);
    }

  
    }