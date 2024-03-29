// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './token/IUSDI.sol';
import './token/UFragments.sol';
import './_external/IERC20.sol';

contract USDI is UFragments, IUSDI{

  address public _reserveAddress;
  IERC20 public _reserve;

  address public _lenderAddress;
  address public _vaultMasterAddress;

  modifier onlyVaultMaster{
    require(msg.sender == _vaultMasterAddress, "only vault master");
    _;
  }

  event Deposit(address indexed _from, uint256 _value);
  event Withdraw(address indexed _from, uint256 _value);
  event Mint(address to, uint256 _value);
  event Burn(address from, uint256 _value);

  event Donation(address indexed _from, uint256 _value, uint256 _totalSupply);

  constructor(address reserveAddress) UFragments("USDI Token","USDI") {
    //ropstein
    _reserveAddress = reserveAddress;
    _reserve = IERC20(_reserveAddress);
  }

  function deposit(uint256 amount) override external {
    require(amount > 0,'Cannot deposit 0');
    uint256 allowance = _reserve.allowance(msg.sender,address(this));
    require(allowance >= amount, 'Insufficient Allowance');
    _reserve.transferFrom(msg.sender,address(this),amount);
    _gonBalances[msg.sender] = _gonBalances[msg.sender] + amount * _gonsPerFragment;
    _totalSupply = _totalSupply + amount;
    _totalGons = _totalGons + amount * _gonsPerFragment;
    emit Deposit(msg.sender,amount);
  }

  function withdraw(uint256 amount) override external {
    require(amount > 0, 'Cannot withdraw 0');
    uint256 allowance = this.allowance(msg.sender,address(this));
    require(allowance >= amount, 'Insufficient Allowance');
    uint256 balance = _reserve.balanceOf(address(this));
    require(balance >= amount, 'Insufficient Reserve in Bank');
    _reserve.transferFrom(address(this),msg.sender,amount);
    _gonBalances[msg.sender] = _gonBalances[msg.sender] - amount * _gonsPerFragment;
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - amount * _gonsPerFragment;
    emit Withdraw(msg.sender,amount);
  }

  function setVaultMaster(address vault_master_address) override external onlyOwner {
    _vaultMasterAddress = vault_master_address;
  }

  function mint(uint256 amount) override external onlyOwner {
    require(amount > 0, 'Cannot mint 0');
    _gonBalances[msg.sender] = _gonBalances[msg.sender] + amount * _gonsPerFragment;
    _totalSupply = _totalSupply + amount;
    _totalGons = _totalGons + amount * _gonsPerFragment;
    emit Mint(msg.sender, amount);
  }

  function burn(uint256 amount) override external onlyOwner {
    require(amount > 0, 'Cannot burn 0');
    _gonBalances[msg.sender] = _gonBalances[msg.sender] - amount * _gonsPerFragment;
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - amount * _gonsPerFragment;
    emit Burn(msg.sender, amount);
  }

  function vault_master_mint(address target, uint256 amount) override external onlyVaultMaster {
    _gonBalances[target] = _gonBalances[target] + amount * _gonsPerFragment;
    _totalSupply = _totalSupply + amount;
    _totalGons = _totalGons + amount * _gonsPerFragment;
    emit Burn(target, amount);
  }

  function vault_master_burn(address target, uint256 amount) override external onlyVaultMaster {
    require(_gonBalances[target] > (amount * _gonsPerFragment),"not enough balance");
    _gonBalances[target] = _gonBalances[target] - amount * _gonsPerFragment;
    _totalSupply = _totalSupply - amount;
    _totalGons = _totalGons - amount * _gonsPerFragment;
    emit Burn(target, amount);
  }

  function vault_master_donate(uint256 amount) override external onlyVaultMaster{
    _totalSupply = _totalSupply + amount;
    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }
    _gonsPerFragment = _totalGons / _totalSupply;
    emit Donation(msg.sender, amount, _totalSupply);
  }

  function reserveRatio() override external view returns (uint256 e18_reserve_ratio){
    e18_reserve_ratio = _reserve.balanceOf(address(this)) * 1e18 / _totalSupply;
  }

}
