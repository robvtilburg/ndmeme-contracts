async function main() {
  const NdMemeVoting = await ethers.getContractFactory("NdMemeVoting")
  // Start deployment, returning a promise that resolves to a contract object
  const ndmeme_voting = await NdMemeVoting.deploy()
  console.log(ndmeme_voting)
  console.log("Contract deployed to address:", ndmeme_voting.target)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })