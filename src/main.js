import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import marketplaceAbi from '../contract/marketplace.abi.json'
import erc20Abi from "../contract/erc20.abi.json"


const ERC20_DECIMALS = 18
const MPContractAddress = "0xF2CBC3B9F6d07dffed211B3a1B6357824e6dDC88"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

let kit
let contract
let wigs = []

const connectCeloWallet = async function () {
  if (window.celo) {
    notification("⚠️ Please approve Glamoriah DApp to gain access...")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

const getWigs = async function() {
  const _num_of_wigs = await contract.methods.get_num_of_wigs().call()
  const _wigs = []

  for (let i = 0; i < _num_of_wigs; i++) {
    let _wig = new Promise(async (resolve, reject) => {
      let p = await contract.methods.get_wig(i).call()
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        price: new BigNumber(p[4]),
        temp_price: new BigNumber(p[5]),
        total_units: p[6],
        units_sold: p[7],
        units_remaining: p[8],
        rating: p[9],
        rating_points: p[10],
        rated_by : p[11],
      })
    })
    _wigs.push(_wig)
  }
  wigs = await Promise.all(_wigs)
  displayWigs()
}


function displayWigs() {
  document.getElementById("marketplace").innerHTML = ""
  wigs.forEach((_wig) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-4"
    newDiv.innerHTML = WigTemplate(_wig)
    document.getElementById("marketplace").appendChild(newDiv)
  })
}



function WigTemplate(_wig) {
  return `
  <div class='container-fluid'>
  <div class="card mx-auto col-md-3 col-10 mt-5">
      <img class='mx-auto img-thumbnail'
          src="${_wig.image}"
          width="auto" height="auto"/>
          <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_wig.owner)}
        </div>
          <div class="position-absolute top-0 end-0 bg-light mt-4 px-2 py-1 rounded-start">sold: ${
            _wig.units_sold
          } pcs</div>
          <div class="position-absolute top-0 end-1 bg-light mt-4 px-2 py-1 rounded-start">In-stock: ${
            _wig.units_remaining
          } pcs</div>
      <div class="card-body text-center mx-auto">
          <div class='cvp'>
              <h4 class="card-title font-weight-bold text-success">${_wig.name}</h4>
              <p class="card-text text-danger text-muted">${_wig.description}</p>
              <span class="card-text">price: ${_wig.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cusd</span><br/>
              ${_wig.rating == 0 ? "" : `<span class="card-text">rating: ${_wig.rating} / 5</span>`}
              ${_wig.owner === kit.defaultAccount ?
                `
                <a  class="btn btn-outline-primary rate editUnitsBtn px-auto" id=${_wig.index}>Edit Units</a><br />
                <a  class="btn btn-outline-dark rate editDescriptionBtn px-auto" id=${_wig.index}>Edit Description</a><br />
                <a  class="btn btn-outline-success rate discountBtn px-auto" id=${_wig.index}>Initiate Discount</a><br />
                <a  class="btn btn-outline-danger rate endDiscountBtn px-auto" id=${_wig.index}>End Discount</a>
                `
              :
            `<a  class="btn btn-outline-dark rate rateWigBtn px-auto" id=${_wig.index}>Rate Wig</a><br />
            ${_wig.units_remaining == 0 ? ``
            :
          `<a  class="btn btn-success buy buyBtn px-auto" id=${_wig.index}> Buy Wig </a>`}`}
              
          </div>
      </div>
  </div>

</div>
    `}

function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}


window.addEventListener('load', async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getWigs()
  notificationOff()
});


document
  .querySelector("#newWigButton")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newWigName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newWigDescription").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString(),
      document.getElementById("newUnits").value,
    ]
    notification(`⌛ Adding "${params[0]}"...`)
    try {
      const result = await contract.methods
        .set_wig(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 You successfully added "${params[0]}". 🎉`)
    getWigs()
  })

document.querySelector("#donateBtn").addEventListener("click", async (e) => {
  let _amount = prompt("Donation Amount (cUSD) ", 2)
  _amount = new BigNumber(_amount).shiftedBy(ERC20_DECIMALS).toString()
  notification("⌛ Waiting for Donation approval...")
  try {
    await approve(_amount)
  } catch (error) {
    notification(`⚠️ ${error}.`)
  }
  notification(`⌛ Donation in progress`)
  try {
    const result = await contract.methods
      .tip_us(_amount)
      .send({ from: kit.defaultAccount })
    notification(`Donation Successful`)
    getWigs()
    getBalance()
  } catch (error) {
    notification(`⚠️ ${error}.`)
  }
})

 document.querySelector("#marketplace").addEventListener("click", async (e) => {

  
  if (e.target.className.includes("buyBtn")) {
    const index = e.target.id
    let units = prompt("How many? ", 1)
    notification("⌛ Waiting for payment approval...")
    try {
      await approve(wigs[index].price)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    
    notification(`⌛ Awaiting payment for "${wigs[index].name}"...`)
    try {
      const result = await contract.methods
        .buy_wig(index,units)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully bought "${wigs[index].name}". 🎉`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }



  if (e.target.className.includes("discountBtn")) {
    const index = e.target.id
    let _price = new BigNumber(prompt("Enter new Price",1)).shiftedBy(ERC20_DECIMALS).toString()
    notification("⌛ Waiting for discount approval...")
    try {
      await approve(_price)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ starting discount of "${wigs[index].name}"...`)
    try {
      const result = await contract.methods
        .discount(index, _price)
        .send({ from: kit.defaultAccount })
      notification(`🎉 discount sale of "${wigs[index].name}" successful. 🎉`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }

  if (e.target.className.includes("endDiscountBtn")) {
    const index = e.target.id
    notification(`⌛ ending discount of "${wigs[index].name}"...`)
    try {
      const result = await contract.methods
        .end_discount(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 discount sale of "${wigs[index].name}" successful. 🎉`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }

  if (e.target.className.includes("editUnitsBtn")) {
    const index = e.target.id
    let _units = prompt("Enter new units",1)
    notification(`⌛ editing units of "${wigs[index].name}"...`)
    try {
      const result = await contract.methods
        .edit_unit(index,_units)
        .send({ from: kit.defaultAccount })
      notification(`🎉 new units established  successfully. 🎉`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }

  if (e.target.className.includes("editDescriptionBtn")) {
    const index = e.target.id
    let _description = prompt("Enter new Description"," ")
    notification(`⌛ editing description of "${wigs[index].name}"...`)
    try {
      const result = await contract.methods
        .edit_description(index,_description)
        .send({ from: kit.defaultAccount })
      notification(`description updated`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }

  if (e.target.className.includes("rateWigBtn")) {
    const index = e.target.id
    let _rate = prompt("Rate (1-5): ",4)
    if (Number(_rate)>5){_rate = "4"}
    else if (Number(_rate)<0){_rate = "1"}
    notification(`⌛ rating   "${wigs[index].name}"...`)
    try {
      const result = await contract.methods
        .rate_wig(index,_rate)
        .send({ from: kit.defaultAccount })
      notification(`Thank you for rating`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }

  if (e.target.className.includes("rateSellerBtn")) {
    const index = e.target.id
    let _rate = prompt("Rate (1-5): ",4)
    if (Number(_rate)>5){_rate = "4"}
    else if (Number(_rate)<0){_rate = "1"}
    notification(`⌛ rating   "${wigs[index].owner}"...`)
    try {
      const result = await contract.methods
        .rate_seller(index,_rate)
        .send({ from: kit.defaultAccount })
      notification(`Thank you for rating`)
      getWigs()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }

})
