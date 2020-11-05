var FIRE = artifacts.require("./FIRE.sol");

module.exports = function(deployer){
    const _name = 'FIRE Network';
    const _symbol = 'FIRE';
    const -decimals = 18;
    
    deployer.deploy(FIRE, _name, _symbol, _decimals);
};
