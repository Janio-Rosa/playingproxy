// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract ImplV1 {
    uint public totalSupply;
    mapping(address => uint) public userStakingTokens;

    function fakeStaking(uint amount)external {
        userStakingTokens[msg.sender] += amount;
        totalSupply += amount;
    }
}

contract ImplV2 {
    uint public totalSupply;
    mapping(address => uint) public userStakingTokens;

    function fakeStaking(uint amount)external {
        userStakingTokens[msg.sender] += amount;
        totalSupply += amount;
    }

    function fakeUnStaking(uint amount)external {
        userStakingTokens[msg.sender] -= amount;
        totalSupply -= amount;
    }
}

contract MainProxy {

    bytes32 public constant IMPL_SLOT = bytes32(uint(keccak256("eip1967.proxy.implementation"))-1);
    bytes32 public constant ADMIN_SLOT = bytes32(uint(keccak256("eip1967.proxy.admin"))-1);

    constructor(){
        _setAdmin(msg.sender);
    }

    /*function _setAdmin(address _newAdmin)private {

    }*/

    function _delegate(address _impl) private {
        /* instead of the solidity delegate, we will use assembly to force returning data
        (bool ok, bytes memory resData) = _impl.delegatecall(msg.data);
        require(ok, "delegating to implementation failed");
        */
        assembly{
            calldatacopy(0,0,calldatasize())
            let result := delegatecall( gas(), _impl, 0, calldatasize(), 0, 0 )
            returndatacopy(0,0,returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(_getImpl());
    }
    receive() external payable {
        _delegate(_getImpl());
    }

    function upgradeTo(address _newImpl) external {
        require(_getAdmin()==msg.sender,"User not admin, thus not authorized to do upgrades");
        _setImpl(_newImpl);
    }

    function _getAdmin() private view returns (address){
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function _setAdmin(address _newAdmin) private  {
        StorageSlot.getAddressSlot(ADMIN_SLOT).value=_newAdmin;
    }

    function _getImpl()private view returns (address){
        return StorageSlot.getAddressSlot(IMPL_SLOT).value;
    }
    function _setImpl(address _newImpl) private  {
        StorageSlot.getAddressSlot(IMPL_SLOT).value=_newImpl;
    }
    function admin() external view returns (address){
        return _getAdmin();
    }
    function impl()external view returns (address){
        return _getImpl();
    }
}

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 _slot)internal pure returns (AddressSlot storage r){
        assembly{
            r.slot := _slot
        }
    }
}

contract TestingLibrary {
    //considering that solidity storage slot varies from 0 to 2^256 (that would make impractical to use all storage slots )
    bytes32 public constant TESTING_SLOT = bytes32(
        uint(keccak256("ANY_STRING_TO_TEST"))-1
    );

    function getMySlot()public view returns (address){
        return StorageSlot.getAddressSlot(TESTING_SLOT).value;
    }

    function setMySlot(address _newAddress)external {
        StorageSlot.getAddressSlot(TESTING_SLOT).value=_newAddress;
    }

}
