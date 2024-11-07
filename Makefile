include .env

# Ensure all targets are treated as phony (not representing files)
.PHONY: install build deploy-sepolia deploy-sepolia-with-args inspect-abi

install all : forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install forge-std --no-commit

build : forge build

inspect-methods:; forge inspect Escrow methods

deploy-sepolia:; forge script script/DeployEscrow.s.sol:DeployEscrow --rpc-url ${SEPOLIA_RPC_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} --private-key ${PRIVATE_KEY} --legacy --broadcast --verify -vvvv


sepolia-deploy:; forge create --rpc-url ${SEPOLIA_RPC_URL} \
    --constructor-args 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
    --interactive \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify \
	--legacy \
    src/Escrow.sol:Escrow