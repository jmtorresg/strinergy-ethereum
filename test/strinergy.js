const EnergyToken = artifacts.require("EnergyToken");
const AccessToken = artifacts.require("AccessToken");

contract("When distributing production", accounts => {
    it('should distribute profits correctly', async () => {
        const AT = await AccessToken.deployed();
        const ET = await EnergyToken.deployed();
        const project = AT.address;
        const meter = accounts[0];
        const participant1 = accounts[1];
        const participant2 = accounts[2];
        const participant3 = accounts[3];

        await AT.transfer(participant1, 4500);
        await AT.transfer(participant2, 4500);
        await AT.transfer(participant3, 4500, {from: participant2})
        await ET.registerProject(project);
        await ET.registerMeter(meter, project);
        await ET.productionNotify(20546, {from: meter});

        const ATBalance1 = (await AT.balanceOf(participant1)).toNumber();
        const ATBalance2 = (await AT.balanceOf(participant2)).toNumber();
        const ATBalance3 = (await AT.balanceOf(participant3)).toNumber();
        expect(ATBalance1).to.equal(4500);
        expect(ATBalance2).to.equal(0);
        expect(ATBalance3).to.equal(4500);
        
        const ETBalance1 = (await ET.balanceOf(participant1)).toNumber();
        const ETBalance2 = (await ET.balanceOf(participant2)).toNumber();
        const ETBalance3 = (await ET.balanceOf(participant3)).toNumber();
        const ETRemainingBalance = (await ET.projectBalance(project)).toNumber();
        expect(ETBalance1).to.equal(9000);
        expect(ETBalance2).to.equal(0);
        expect(ETBalance3).to.equal(9000);
        expect(ETRemainingBalance).to.equal(546);
    });
});