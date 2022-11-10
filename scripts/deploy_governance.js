const { ethers , upgrades } = require("hardhat");

async function main(){
    const Governance = await ethers.getContractFactory("GovernanceV2");
    const governance = await Governance.deploy("0xf4a904478dB17d9145877bCF95F47C92FeC5eA8d","0x33707798e5118EED72766afE566423BCBeaf937b","0x000000000000000000000000000000000000dEaD")
    await governance.deployed(); 
    console.log("Governance : ",governance.address)
}

main()