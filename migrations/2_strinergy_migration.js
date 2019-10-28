const AccessToken = artifacts.require("AccessToken");
const EnergyToken = artifacts.require("EnergyToken");

const config = {
    AT_SUPPLY: 10000,
};

module.exports = function (deployer) {
    deployer.deploy(AccessToken, config.AT_SUPPLY);
    deployer.deploy(EnergyToken);
}