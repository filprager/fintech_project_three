// @TODO: Update this address to match your deployed TaskMarket contract!
const contractAddress = "0x7B5A0459625Fcc8Be2e527be3FD708B0E76eFfAD";
const tokenAddress = "0x055B43735c3f994862b2967803e1e21e62Ed3793"; 

const dApp = {
  ethEnabled: function() {
    // If the browser has an Ethereum provider (MetaMask) installed
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      window.ethereum.enable();
      return true;
    }
    return false;
  },
  collectVars: async function() {
    // get Task tokens
    this.tokens = [];
    this.totalSupply = await this.marsContract.methods.totalSupply().call();

    // fetch json metadata from IPFS (name, description, image, etc)
    const fetchMetadata = (reference_uri) => fetch(`https://gateway.pinata.cloud/ipfs/${reference_uri.replace("ipfs://", "")}`, { mode: "cors" }).then((resp) => resp.json());

    for (let i = 1; i <= this.totalSupply; i++) {
      try {
        const token_uri = await this.marsContract.methods.tokenURI(i).call();
        console.log('token uri', token_uri)
        const token_json = await fetchMetadata(token_uri);
        console.log('token json', token_json)                                                                                                                                

        this.tokens.push({
          tokenId: i,
          lowestBid: Number(await this.marsContract.methods.lowestBid(i).call()),
          taskFinished: Boolean(await this.marsContract.methods.taskFinished(i).call()),
          auctionEnded: Boolean(await this.marsContract.methods.auctionEnded(i).call()),
          Satisfied: Boolean(await this.marsContract.methods.Satisfied(i).call()),
          pendingBids: Number(await this.marsContract.methods.pendingBids(i, this.accounts[0]).call()),
          pendingDeposit: Number(await this.marsContract.methods.pendingDeposit(i).call()),
          auction: new window.web3.eth.Contract(
            this.auctionJson,
            await this.marsContract.methods.auctions(i).call(),
            { defaultAccount: this.accounts[0] }
          ),
          owner: await this.marsContract.methods.ownerOf(i).call(),
          lowestBidder: await this.marsContract.methods.lowestBidder(i).call(),
          ...token_json
        });
      } catch (e) {
        console.log(JSON.stringify(e));
      }
    }
  },
  setAdmin: async function() {
    // if account selected in MetaMask is the same as owner then admin will show
    if (this.isAdmin) {
      $(".dapp-admin").show();
    } else {
      $(".dapp-admin").hide();
    }
  },
  updateUI: async function() {
    console.log("updating UI");
    // refresh variables
    await this.collectVars();
    
    $("#dapp-tokens").html("");
    this.tokens.forEach((token) => {
      try {
        let endAuction = `<a id="${token.tokenId}"  href="#"  onclick="dApp.endAuction(event)">End_Auction</a>`;
        let stopAuction = `<a id="${token.tokenId}"  href="#" onclick="dApp.stopAuction(event)">Stop_Auction</a>`;
        let satisfied = `<a id="${token.tokenId}"   href="#" onclick="dApp.finished(event)">Satisfied</a>`;
        let unsatisfied = `<a id="${token.tokenId}"  href="#" onclick="dApp.unfinished(event)">unSatisfied</a>`;
        let bid = `<a id="${token.tokenId}" href="#" onclick="dApp.bid(event);">Bid</a>`; 
        let allowance = `<a id="${token.tokenId}" href="#" onclick="dApp.increaseallowance(event);">Increase_Allowance</a>`;      
        let owner = `Owner: ${token.owner}`;
        let withdraw = `<a id="${token.tokenId}" href="#" onclick="dApp.withdraw(event)">Withdraw</a>`;
        let deposit = `<a id="${token.tokenId}" href="#" onclick="dApp.deposit(event);">Deposit</a>`;
        let pendingBudget = `Budget : ${token.pendingDeposit} wei`;
        let lowestbid = `LowestBid : ${token.lowestBid} wei`;
        let recharge = `<a id="${token.tokenId}" href="#" onclick="dApp.recharge(event)">Recharge</a>`;
          
          $("#dapp-tokens").append(
            `<div class="col m6">
              <div class="card">
                <div class="card-image">
                  <img id="dapp-image" src="https://gateway.pinata.cloud/ipfs/${token.image.replace("ipfs://", "")}">
                  <span id="dapp-name" class="card-title">${token.name}</span>
                </div>
                <div class="card-action">
                  <input type="number" name="dapp-wei"  id="${token.tokenId}" placeholder="Amount"   ${token.auctionEnded ? 'disabled' : ''}>
                  

                  ${this.accounts[0] !== token.owner && !token.auctionEnded ? bid : ''}
                  ${token.auctionEnded || this.accounts[0] == token.owner ? '' : allowance}                 
                  ${token.auctionEnded ? '' : recharge}<br>
                  
                  ${this.accounts[0] !== token.lowestBidder && token.pendingBids > 0  ? withdraw : ''}
                  ${this.accounts[0] == token.owner && !token.auctionEnded ? '': owner}<br>
                  ${this.accounts[0] == token.owner && token.lowestBidder !== token.owner && !token.auctionEnded ? endAuction : ''}
                  ${this.accounts[0] == token.owner && !token.auctionEnded ? stopAuction : ''}
                  ${this.accounts[0] == token.owner && !token.auctionEnded ? deposit : ''}<br>
                  ${pendingBudget}<br>
                  ${lowestbid}<br>
                  ${this.accounts[0] == token.owner && token.auctionEnded && !token.taskFinished ? satisfied : ''}
                  ${this.accounts[0] == token.owner && token.auctionEnded && !token.taskFinished ? unsatisfied : ''}
                  ${token.Satisfied && token.taskFinished ? "Satisfied" : ''}
                  ${!token.Satisfied && token.taskFinished ? "unSatisfied" : ''}
                  
                </div>
              </div>
            </div>`
          
          );
      } catch (e) {
        alert(JSON.stringify(e));
      }
    });
      
    // hide or show admin functions based on contract ownership
    this.setAdmin();
  },

  deposit: async function(event) {
    const tokenId = $(event.target).attr("id");
    var wei= document.getElementById(tokenId).value;
    console.log(wei);
    await this.marsContract.methods.deposit(tokenId).send({from: this.accounts[0], value: wei}, async () => {
      await this.updateUI();
    });
  },

  recharge: async function(event) {
    const tokenId = $(event.target).attr("id");
    var wei= document.getElementById(tokenId).value;
    console.log(wei);
    await this.marsContract.methods.recharge().send({from: this.accounts[0], value: wei}, async () => {
      await this.updateUI();
      
    });
  },

  bid: async function(event) {
    const tokenId = $(event.target).attr("id");
    var airt = document.getElementById(tokenId).value;
    console.log(airt);
    await this.marsContract.methods.bid(tokenId, airt).send({from: this.accounts[0]}, async () => {
      await this.updateUI();
    });
  },

  increaseallowance: async function(event) {
    const tokenId = $(event.target).attr("id");
    var airt = document.getElementById(tokenId).value;
    console.log(airt);
    await this.tokenContract.methods.increaseAllowance(this.contractAddress, airt).send({from: this.accounts[0]}, async () => {
      await this.updateUI();
    });
  },

  endAuction: async function(event) {
    const tokenId = $(event.target).attr("id");
    await this.marsContract.methods.endAuction(tokenId).send({from: this.accounts[0]}, async () => {
      await this.updateUI();
    });
  },
  stopAuction: async function(event) {
    const tokenId = $(event.target).attr("id");
    await this.marsContract.methods.auctionStop(tokenId).send({from: this.accounts[0]}, async () => {
      await this.updateUI();
    });
  },
  finished: async function(event) {
    const tokenId = $(event.target).attr("id");
    await this.marsContract.methods.finishoftask(tokenId).send({from: this.accounts[0]}, async () => {
      await this.updateUI();
    });
  },
  unfinished: async function(event) {
    const tokenId = $(event.target).attr("id");
    await this.marsContract.methods.unfinishoftask(tokenId).send({from: this.accounts[0]}, async () => {
      await this.updateUI();
    });
  },
  withdraw: async function(event) {
    const tokenId = $(event.target).attr("id");
    // await this.tokens[tokenId].auction.methods.withdraw().send({from: this.accounts[0]}, async () => {
    await this.marsContract.methods.withdraw(tokenId).send({from: this.accounts[0]}, async () => {  
      await this.updateUI();
    });
  },
  
  registerTask: async function() {
    const name = $("#dapp-register-name").val();
    const homeowner = $("#dapp-homeowner").val();
    const image = document.querySelector('input[type="file"]');

    const pinata_api_key = $("#dapp-pinata-api-key").val();
    const pinata_secret_api_key = $("#dapp-pinata-secret-api-key").val();

    if (!pinata_api_key || !pinata_secret_api_key || !name || !image) {
      M.toast({ html: "Please fill out then entire form!" });
      return;
    }

    const image_data = new FormData();
    image_data.append("file", image.files[0]);
    image_data.append("pinataOptions", JSON.stringify({cidVersion: 1}));

    try {
      M.toast({ html: "Uploading Image to IPFS via Pinata..." });
      const image_upload_response = await fetch("https://api.pinata.cloud/pinning/pinFileToIPFS", {
        method: "POST",
        mode: "cors",
        headers: {
          pinata_api_key,
          pinata_secret_api_key
        },
        body: image_data,
      });

      const image_hash = await image_upload_response.json();
      const image_uri = `ipfs://${image_hash.IpfsHash}`;

      M.toast({ html: `Success. Image located at ${image_uri}.` });
      M.toast({ html: "Uploading JSON..." });

      const reference_json = JSON.stringify({
        pinataContent: { name, image: image_uri },
        pinataOptions: {cidVersion: 1}
      });

      const json_upload_response = await fetch("https://api.pinata.cloud/pinning/pinJSONToIPFS", {
        method: "POST",
        mode: "cors",
        headers: {
          "Content-Type": "application/json",
          pinata_api_key,
          pinata_secret_api_key
        },
        body: reference_json
      });

      const reference_hash = await json_upload_response.json();
      const reference_uri = `ipfs://${reference_hash.IpfsHash}`;

      M.toast({ html: `Success. Reference URI located at ${reference_uri}.` });
      M.toast({ html: "Sending to blockchain..." });

      await this.marsContract.methods.registerTask(reference_uri, homeowner).send({from: this.accounts[0]}, async () => {
        $("#dapp-register-name").val("");
        $("#dapp-register-image").val("");
        await this.updateUI();
      });

    } catch (e) {
      alert("ERROR:", JSON.stringify(e));
    }
  },
  main: async function() {
    // Initialize web3
    if (!this.ethEnabled()) {
      alert("Please install MetaMask to use this dApp!");
    }

    this.accounts = await window.web3.eth.getAccounts();
    this.contractAddress = contractAddress;
    this.tokenAddress = tokenAddress;

    this.marsJson = await (await fetch("./TaskMarket.json")).json();
    this.auctionJson = await (await fetch("./TaskAuction.json")).json();
    this.tokenJson = await (await fetch("./airtoken.json")).json();

    this.tokenContract = new window.web3.eth.Contract(
      this.tokenJson,
      this.tokenAddress,
      { defaultAccount: this.accounts[0] }
    );
    console.log("Contract object", this.tokenContract);
    
    this.marsContract = new window.web3.eth.Contract(
      this.marsJson,
      this.contractAddress,
      { defaultAccount: this.accounts[0] }
    );
    console.log("Contract object", this.marsContract);

    this.isAdmin = this.accounts[0] == await this.marsContract.methods.owner().call();

    await this.updateUI();
  }
};

dApp.main();