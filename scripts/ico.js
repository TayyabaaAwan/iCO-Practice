const hre = require("hardhat");
async function main() {
    // We get the contract to deploy
    const ico = await hre.ethers.getContractFactory("ICO");
    console.log("Deploying Contract . . . . ");
    const ICO = await ico.deploy("0x64ddB6c1D4dFa10042d02a08bD1373412F9d4b17", "0x9396B453Fad71816cA9f152Ae785276a1D578492", "10000"); 
  
    await ICO.deployed();
    console.log(
        ICO.address
  );
  }

  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
