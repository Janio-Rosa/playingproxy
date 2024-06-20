//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract StakeImplV1 {
    //Just to test proxies implementations - change to ERC20 later on
    mapping(address => uint) public stakingPerUser;
    uint public totalSupply;
    function stake(uint _amount) external {
        stakingPerUser[msg.sender]+=_amount;
        totalSupply+=_amount;
    }
}

contract StakeImplV2 {
    mapping(address => uint) public stakingPerUser;
    uint public totalSupply;
    function stake(uint _amount) external {
        stakingPerUser[msg.sender]+=_amount;
        totalSupply+=_amount;
    }
    function unStake(uint _amount) external {
        stakingPerUser[msg.sender]-=_amount;
        totalSupply-=_amount;
    }
}

contract Proxy {
    bytes32 public constant IMPL_SLOT = bytes32(uint(keccak256("eip1967.proxy.implementation"))-1);
    bytes32 public constant ADMIN_SLOT = bytes32(uint(keccak256("eip1967.proxy.admin"))-1);

    constructor(){
        _setAdminAddr(msg.sender);
    }
    modifier onlyAdmin {
        require(msg.sender==_getAdminAddr(),"User not authorized. Only admin can perform this operation");
        _;
    }

    function _getAdminAddr()private view returns (address){
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }
    function _setAdminAddr(address _newAddr)private {
        StorageSlot.getAddressSlot(ADMIN_SLOT).value=_newAddr;
    }
    function _getImplAddr()private view returns (address){
        return StorageSlot.getAddressSlot(IMPL_SLOT).value;
    }
    function _setImplAddr(address _newAddr)private {
        StorageSlot.getAddressSlot(IMPL_SLOT).value=_newAddr;
    }

    function upgradeImpl(address _newImpl)public onlyAdmin {
        _setImplAddr(_newImpl);
    }
    fallback() external payable {
        _delegate(_getImplAddr());
     }
    receive() external payable { 
        _delegate(_getImplAddr());
    }
    function _delegate(address _impl)private returns (bytes32){
        assembly{
            calldatacopy(0,0,calldatasize())
            let ret := delegatecall(gas(),_impl,0,calldatasize(),0,0)
            returndatacopy(0,0,returndatasize())
            switch ret 
            case 0 {
                revert(0,returndatasize())
            }
            return(0,returndatasize())
        }
    }
    function checkAdmin()public view returns (address){
        return _getAdminAddr();
    }
    function checkImpl()public view returns (address){
        return _getImplAddr();
    }    
}

contract ProxyAdmin {

}

library StorageSlot {
    struct AddressSlot {
        address value;
    }
    function getAddressSlot(bytes32 _slot)public pure returns (AddressSlot storage r) {
        assembly {
            r.slot := _slot
        }
    }
}
