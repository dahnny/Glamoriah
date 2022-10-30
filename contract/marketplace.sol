// SPDX-License-Identifier: MIT

/// @dev solitity version.
pragma solidity >=0.7.0 <0.9.0; //this contract works for solidty version from 0.7.0 to less than 0.9.0

/**
* @dev REquired interface of an ERC20 compliant contract.
*/
interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

/**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address, uint256) external returns (bool);

 /**
     * @dev Transfers `tokenId` token from `from` to `to`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);


    function totalSupply() external view returns (uint256);

/*
*@dev Returns the number of tokens in``owner``'s acount.
*/
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

/*
*@dev Emitted when `tokenId` token is transferred from `from` to `to`.
*/
    event Transfer(address indexed from, address indexed to, uint256 value);

/*
*@dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
*/  
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Marketplace {

    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    address internal glamoriahAddress = 0x038eaa59Ecf6EcE3F7BcDa08eaF18B36A1786752 ;
    uint private num_of_wigs = 0;
    uint private wig_index = 0;

    struct Wig{
        address payable owner;
        string name;
        string url;
        string description;
        uint256 price;
        uint256 temp_price;
        uint256 total_units;
        uint256 units_sold;
        uint256 units_remaining;
        uint256 rating;
        uint256 rating_points;
        uint256 rated_by;
    }

    struct Seller{
        address payable account;
        uint256 rating;
        uint256 rating_points;
        uint256 rated_by;
    }
    
    mapping(uint => Wig) private wigs;
    mapping(address => Seller) private sellers;
    mapping(uint => bool) private in_marketplace;

    modifier is_in_marketplace(uint256 _index){
        require(in_marketplace[_index], "Wig does not exist");
        _;
    }

    modifier is_owner(uint _index){
        require(wigs[_index].owner == msg.sender, "Creator only fuctionality!");
        _;
    }

    function set_wig(
        string calldata _name,
        string calldata _url,
        string calldata _description,
        uint256 _price,
        uint256 _total_uints
    ) public{
        require(bytes(_name).length > 0,"name field cannot be empty");
        require(bytes(_url).length > 0,"name field cannot be empty");
        require(bytes(_description).length > 0,"description field cannot be empty");
        require(_price > 0," price field must be at least 1 wei");
        require(_total_uints > 0," Total units cannot be empty");

        uint256 _temp_price = _price;
        uint256 _units_sold = 0;
        uint256 _rating = 0;
        uint256 _rating_points = 0;
        uint256 _rated_by = 0;

        wigs[wig_index] = Wig(
            payable(msg.sender),
            _name,
            _url,
            _description,
            _price,
            _temp_price,
            _total_uints,
            _units_sold,
            _total_uints - _units_sold,
            _rating,_rating_points,_rated_by
        );
        sellers[msg.sender] = Seller(
            payable(msg.sender),0,0,0
        );
        in_marketplace[wig_index] = true;
        num_of_wigs +=1;
        wig_index +=1;

    }

    function get_wig(
        uint256 _wig_index
    ) public view is_in_marketplace(_wig_index) returns(Wig memory){
        return(wigs[_wig_index]);
    }

    function rate_wig(
        uint256 _wig_index,
        uint256 _rate
    ) public {
        require(wigs[_wig_index].owner != msg.sender, "Owners cannot rate their own products");
        wigs[_wig_index].rating_points += _rate;
        wigs[_wig_index].rated_by++;
        wigs[_wig_index].rating = wigs[_wig_index].rating_points / wigs[_wig_index].rated_by ;
    }

    function buy_wig(
        uint256 _wig_index,
        uint256 _units
    ) public payable is_in_marketplace(_wig_index){
        require(_units > 0 , "Units cannot be empty");
        require(wigs[_wig_index].owner != msg.sender, "Owners cannot buy their own products");
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                wigs[_wig_index].owner,
                wigs[_wig_index].price * _units
            ),
            "Transfer failed."
        );
        wigs[_wig_index].units_sold += _units;
        wigs[_wig_index].units_remaining = wigs[_wig_index].total_units - wigs[_wig_index].units_sold;
    }

    function discount(uint256 _wig_index, uint256 _price) public is_in_marketplace(_wig_index) is_owner(_wig_index){
        wigs[_wig_index].price = _price;
    }

    function end_discount(uint256 _wig_index) public is_in_marketplace(_wig_index) is_owner(_wig_index){
        wigs[_wig_index].price = wigs[_wig_index].temp_price;
    }

    function edit_unit(uint256 _wig_index ,uint256 _units) public is_in_marketplace(_wig_index) is_owner(_wig_index){
        require((_units)>0, "units cannot be empty");
        wigs[_wig_index].total_units = _units;
        wigs[_wig_index].units_remaining = wigs[_wig_index].total_units - wigs[_wig_index].units_sold;
    }

    function edit_description(uint256 _wig_index ,string calldata _description) public is_in_marketplace(_wig_index) is_owner(_wig_index){
        require(bytes(_description).length >0, "Description cannot be empty");
        wigs[_wig_index].description = _description;
    }

    function rate_seller(address seller, uint256 rate) public {
        require(sellers[seller].account != msg.sender, "You cant rate yourself");
        sellers[seller].rating_points += rate;
        sellers[seller].rating = sellers[seller].rating_points / sellers[seller].rated_by;
        sellers[seller].rated_by ++;
    }
    
    function get_num_of_wigs() public view returns (uint) {
        return (num_of_wigs);
    }

    function tip_us(uint256 _amount) public payable{
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                glamoriahAddress,
                _amount
            ),
            "Transfer failed."
        );
    }

}