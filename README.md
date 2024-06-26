## Escrow Contract

**Description** This is just a basic `Escrow` contract for `Escrow` services for client and developer. Client made a deposit amount based on agreement with the developer to an `Escrow` contract, And it will be released to the developer once the job completed. No one has access to the funds in the contract not even the contract owner, Funds will only be released once the project completed and client has been confirmed. Thus, the funds will be transfered to the `developer` accounts.

 Otherwise the funds will be refunded to the client if the deadline has passed. 
 
 This contract can still be improved it, and it is not production ready yet (maybe in the future )


### Quick Start

 **Clone this repository by run the following command:**
 ```shell
    git clone https://github.com/raazymuhd1/Escrow-Contract.git
 ```

 **Install all dependencies:**
 ```shell
   make install
 ```

 **Compile the contracts**
 ```shell
    make build 
        OR 
    forge build
 ```

 **Run Test to create a project**
 ```shell
    forge test --mt test_createProject -vvv
 ```