### ERC-404
 - `ERC404` is a hybrid token standard that has functionality like `ERC20` and `ERC721`;
 - if u buy a full token `ERC404` not in fraction (0.1, 0.2, 0.3 and so on), you will receive 1 `ERC-721` version of `ERC404`
 - but if u buy a fraction or below 1 (0.1, 0.2 and so on) of `ERC404`, u will not get any `ERC721` but u will get an `ERC20` version of `ERC404` 
 - if you mint/buy a certain amount `ERC721` of `ERC404`, then u need to burn a X amount `ERC20` of `ERC404`


## The type of the token 
 - the type of token will be determined by the amount of token that u holding in your wallet
 - if ur amount of `ERC404` in your wallet is (1), that means u holding 1 NFT
 - if the amount of `ERC404` that u holding is (1.5 / 3.4) that means u holding 1 NFT or 3 NFT `(ERC721)` and 0.5 or 0.4 token `(ERC20)`

 ### Keynote
 - Do not store your private key in .env file, it will be very unsafe to do that
   but store it using `cast wallet import keyName --interactive` command.
   ex: `cast wallet import myKey --interactive`