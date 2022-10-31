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
    address internal glamoriahAddress =
        0x038eaa59Ecf6EcE3F7BcDa08eaF18B36A1786752;
    uint256 private wig_index = 0;

    struct Wig {
        address payable owner;
        string name;
        string url;
        string description;
        uint256 price;
        uint256 temp_price;
        uint256 units_available;
        uint256 units_sold;
        uint256 rating_points;
        uint256 rated_by;
    }

    struct Seller {
        address payable account;
        uint256 rating_points;
        uint256 rated_by;
        bool initialised;
    }

    mapping(uint256 => Wig) private wigs;
    mapping(address => Seller) private sellers;
    mapping(uint256 => bool) private in_marketplace;

    mapping(address => mapping(address => bool)) private ratedSeller;
    mapping(address => mapping(uint => bool)) private ratedWig;

    modifier is_in_marketplace(uint256 _index) {
        require(in_marketplace[_index], "Wig does not exist");
        _;
    }

    modifier is_owner(uint256 _index) {
        require(wigs[_index].owner == msg.sender, "Creator only fuctionality!");
        _;
    }

    /**
        * @dev allow users to add a wig to the marketplace
        * @notice Input data needs to contain only valid/non-empty values
     */
    function set_wig(
        string calldata _name,
        string calldata _url,
        string calldata _description,
        uint256 _price,
        uint256 _total_uints
    ) public {
        require(bytes(_name).length > 0, "name field cannot be empty");
        require(bytes(_url).length > 0, "name field cannot be empty");
        require(
            bytes(_description).length > 0,
            "description field cannot be empty"
        );
        require(_price > 0, " price field must be at least 1 wei");
        require(_total_uints > 0, " Total units cannot be empty");

        Wig storage newWig = wigs[wig_index];
        newWig.owner = payable(msg.sender);
        newWig.name = _name;
        newWig.url = _url;
        newWig.description = _description;
        newWig.price = _price;
        newWig.temp_price = _price;
        newWig.units_available = _total_uints;

        if (!sellers[msg.sender].initialised) {
            sellers[msg.sender] = Seller(payable(msg.sender), 0, 0, true);
        }
        in_marketplace[wig_index] = true;
        wig_index += 1;
    }

    function get_wig(uint256 _wig_index)
        public
        view
        is_in_marketplace(_wig_index)
        returns (Wig memory)
    {
        return (wigs[_wig_index]);
    }

    /**
        * @dev allow users to rate a wig
        * @notice Rate has to be between 1 and 5
     */
    function rate_wig(uint256 _wig_index, uint256 _rate) public {
        require(_rate > 0 && _rate <= 5, "Rate needs to be between 1 and 5");
        require(
            wigs[_wig_index].owner != msg.sender,
            "Owners cannot rate their own products"
        );
        require(!ratedWig[msg.sender][_wig_index], "You have already rated this wig");
        ratedWig[msg.sender][_wig_index] = true;
        wigs[_wig_index].rating_points += _rate;
        wigs[_wig_index].rated_by++;
    }

    /**
        * @dev allow users to buy a wig from the marketplace
        * @param _units the number of wigs to buy
        * @notice stock available for wig needs to be able to fulfill the units specified for this order
     */
    function buy_wig(uint256 _wig_index, uint256 _units)
        public
        payable
        is_in_marketplace(_wig_index)
    {
        Wig storage current_wig = wigs[_wig_index];
        require(_units > 0, "Units cannot be empty");
        require(current_wig.units_available >= _units,"Not enough wigs in stock to fulfill this order");
        require(
            current_wig.owner != msg.sender,
            "Owners cannot buy their own products"
        );
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                current_wig.owner,
                current_wig.price * _units
            ),
            "Transfer failed."
        );
        uint new_units_sold = current_wig.units_sold + _units; 
        current_wig.units_sold = new_units_sold;
        uint new_units_available = current_wig.units_available - _units;
        current_wig.units_available = new_units_available;
    }

    function discount(uint256 _wig_index, uint256 _price)
        public
        is_in_marketplace(_wig_index)
        is_owner(_wig_index)
    {
        wigs[_wig_index].price = _price;
    }

    function end_discount(uint256 _wig_index)
        public
        is_in_marketplace(_wig_index)
        is_owner(_wig_index)
    {
        wigs[_wig_index].price = wigs[_wig_index].temp_price;
    }

    function edit_unit(uint256 _wig_index, uint256 _units)
        public
        is_in_marketplace(_wig_index)
        is_owner(_wig_index)
    {
        require((_units) > 0, "units cannot be empty");
        wigs[_wig_index].units_available = _units;
    }

    function edit_description(uint256 _wig_index, string calldata _description)
        public
        is_in_marketplace(_wig_index)
        is_owner(_wig_index)
    {
        require(bytes(_description).length > 0, "Description cannot be empty");
        wigs[_wig_index].description = _description;
    }


    /**
        * @dev allow users to rate a seller
        * @notice rate specified needs to be between 1 and 5
     */
    function rate_seller(address seller, uint256 rate) public {
        
        require(rate > 0 && rate <= 5, "Rate needs to be between 1 and 5");
        Seller storage current_seller = sellers[seller];
        require(current_seller.initialised, "Seller has not been intialised yet");
        require(
            current_seller.account != msg.sender,
            "You can't rate yourself"
        );
        require(
            !ratedSeller[msg.sender][seller], "You have already rated this seller"
        );
        ratedSeller[msg.sender][seller] = true;
        current_seller.rating_points += rate;
        current_seller.rated_by++;
    }

    function get_num_of_wigs() public view returns (uint256) {
        return (wig_index);
    }

    /**
        * @dev allow users to support the platform's owner
     */
    function tip_us(uint256 _amount) public payable {
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
