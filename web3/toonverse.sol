// SPDX-License-Identifier: MIT
// .----------------.  .----------------.  .----------------.  .-----------------. .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
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
//https://www.toonversestudios.com/

    pragma solidity^0.8.11;


    import "./ERC721A.sol";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol";

    contract TOONVERSE is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public COST = 0.038 ether;
    uint256 public MAX_SUPPLY = 6666;
    uint256 public  immutable MAX_MINT_AMOUNT = 50;
    string public BASE_URI ="https://toonverse.s3.amazonaws.com/";
    string public BASE_EXTENSION = ".json";
    string public NOT_REVEALED_URI= "https://toonverse.s3.amazonaws.com/notRevealed.json";
    bool public PAUSED = true;
    bool public REVEALED = false;

    address public OWNER_AUX = 0x1BcCe17ea705d2a9f09993F8aD7ae3e6a68e1281;
    address public DEV = 0x4538C3d93FfdE7677EF66aB548a4Dd7f39eca785; 
    address public PARTNER =0x11A7D4E65E2086429113658A650e18F126FB4AA0; 

    bytes32 public WHITELIST_MERKLE_ROOT = 0xacbeb311676f565667659156a2922c108ca8dd671396506659566ef845490043;
    mapping(address => bool) public WHITELIST_CLAIMED;
    bool public IS_WHITELIST_ONLY = true;


    constructor() ERC721A("Toonverse", "TOON",MAX_SUPPLY,MAX_MINT_AMOUNT) {
        _safeMint(OWNER_AUX,50);
        _safeMint(PARTNER,50);
        _safeMint(DEV,10);

    }


        modifier onlyDev() {
            require(msg.sender == DEV, 'Only Dev');
            _;
        }


        modifier onlyPartner() {
            require(msg.sender == PARTNER, 'Only PARTNER');
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
    
    function mint(uint256 _mintAmount) public payable  mintChecks(_mintAmount)  {
            if(msg.sender!= owner()){
            checkIfPaused();
            require(_mintAmount<= MAX_MINT_AMOUNT, "Can not exceed max mint amount.");
            require(!IS_WHITELIST_ONLY,"Only whitelist can mint right now.");
            require(msg.value >= COST * _mintAmount, "Not Enough Eth Sent.");
            teamMint(msg.value);
                if(_mintAmount >= 3){
                _mintAmount = _mintAmount * 2;
                _safeMint(msg.sender,_mintAmount);
                }else{
                 _safeMint(msg.sender,_mintAmount);
                 }
            }else{
                 _safeMint(msg.sender,_mintAmount);

            }
    }


    function mintWhiteList(bytes32[] calldata _merkleProof,uint256 _mintAmount) public payable  mintChecks(_mintAmount)  {
            if(msg.sender!= owner()){
            checkIfPaused();
            require(_mintAmount<= MAX_MINT_AMOUNT, "Can not exceed max mint amount.");
            require(IS_WHITELIST_ONLY,"Whitelist no longer available.");   
            require(!WHITELIST_CLAIMED[msg.sender],"Address has already claimed");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof,WHITELIST_MERKLE_ROOT,leaf),"Invalid Proof");
            require(msg.value >= COST * _mintAmount, "Not Enough Eth Sent.");
            teamMint(msg.value);

                if(_mintAmount >= 3){
                _mintAmount = _mintAmount * 2;
                _safeMint(msg.sender,_mintAmount);
                WHITELIST_CLAIMED[msg.sender]=true;

                }else{
                 _safeMint(msg.sender,_mintAmount);
                 WHITELIST_CLAIMED[msg.sender]=true;

                 } 
            }else{
                _safeMint(msg.sender,_mintAmount);
                  }
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

    function setPartner(address _address) public onlyPartner {
        PARTNER = _address;
    }

    function setOwnerAux(address _address) public onlyOwner {
        OWNER_AUX = _address;
    }


    function checkIfPaused() private view  {
        require(!PAUSED,"Contract currently PAUSED.");
    }    
    
    function withdraw(uint256 _amount) public payable onlyOwner {
        
        //Dev 2%         
            uint256 devFee = _amount /50; 
            (bool devBool, ) = payable(DEV).call{value: devFee}("");
            require(devBool);

        //Partner 20%
            uint256 partnerFee = _amount * 1/ 5;
            (bool partnerBool, ) = payable(PARTNER).call{value: partnerFee}("");
            require(partnerBool);

        //Rest goes to Owner of Contract
            uint256 result = _amount - partnerFee - devFee;
            (bool resultBool, ) = payable(owner()).call{value: result}("");
            require(resultBool);    
    }

    function teamMint(uint256 _ethAmount) internal   {
            
            //.04 Dev 
            uint256 devFee = _ethAmount /25; 
            (bool devBool, ) = payable(DEV).call{value: devFee}("");
            require(devBool);

            //.07 Partner
            uint256 partnerFee = _ethAmount * 7/ 100;
            (bool partnerBool, ) = payable(PARTNER).call{value: partnerFee}("");
            require(partnerBool);

            //Rest goes to contract AUX wallet
            uint256 result = _ethAmount - partnerFee - devFee;
            (bool resultBool, ) = payable(OWNER_AUX).call{value: result}("");
            require(resultBool);    
            
            }

  
    }