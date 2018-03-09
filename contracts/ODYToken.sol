pragma solidity ^0.4.18;

import "./Receiver_Interface.sol";
import "./ERC223_Interface.sol";
import "./Ownable.sol";

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */
 
 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y)
            revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y)
            revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0)
            return 0;
        if (x > MAX_UINT256 / y)
            revert();
        return x * y;
    }
}
 
contract ODYToken is ERC223, SafeMath, Ownable {

    mapping(address => uint) balances;
    
    string public name = "Odytoken";
    string public symbol = "ODY";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    event Mint(address indexed to, uint256 amount);
    
    // Function to access name of token
    function name() public view returns (string _name) {
        return name;
    }
    // Function to access symbol of token
    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    // Function to access decimals of token
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    // Function to access total supply of tokens
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function ODYToken () public {
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint _amount) onlyOwner public returns (bool) {
        totalSupply = safeAdd(totalSupply, _amount);
        balances[_to] = safeAdd(balanceOf(_to), _amount);
        Transfer(address(0), _to, _amount);
        Mint(_to, _amount);
        return true;
    }
    
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value)
                revert();
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {
        
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
                //retrieve the size of the code on target address, this needs assembly
                length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value)
            revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value)
            revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    /**
    * @dev Transfers the current balance to the owner and terminates the contract.
    */
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        selfdestruct(_recipient);
    }
}
