const datasetAddress = args[0]
const purchaseWalletAddress = args[1]

if (!datasetAddress) {
  throw "Dataset Address is required"
}

if (!purchaseWalletAddress) {
  throw "Wallet Address purchaser is required"
}

// Max retries HTTP requests are 4 because total HTTP requests a Chainlink Function can do is 5 https://docs.chain.link/chainlink-functions/resources/service-limits
function httpRequest(url, headers, data, retries = 4) {
  return new Promise((resolve, reject) => {
    // Timeout 9000ms is because of the chainlink service limits
    Functions.makeHttpRequest({ url, headers, method: "GET", timeout: 9000 })
      .then((response) => {
        if (response.statusText === "OK") {
          resolve(response.data)
        } else if (retries > 0) {
          console.log(`Retry attempts remaining: ${retries}`)
          setTimeout(() => {
            httpRequest(url, headers, data, retries - 1)
              .then(resolve)
              .catch(reject)
          }, 1000) // retry after 1 second
        } else {
          reject(new Error("Failed after 5 attempts"))
        }
      })
      .catch((error) => {
        if (retries > 0) {
          console.log(`Retry attempts remaining: ${retries}`)
          setTimeout(() => {
            httpRequest(url, headers, data, retries - 1)
              .then(resolve)
              .catch(reject)
          }, 1000) // retry after 1 second
        } else {
          reject(error)
        }
      })
  })
}

const purchaseDataset = httpRequest(
  `http://localhost:5173/api/purchase-dataset/${purchaseWalletAddress}/${datasetAddress}`,
  //   `https://qlog.ai/api/purchase-dataset/${purchaseWalletAddress}/${datasetAddress}`,
  {
    Authorization: `Bearer ${secrets.bearerToken}`,
    "Content-Type": "application/json",
  }
)
  .then((data) => {
    return Functions.encodeString(data.cid)
  })
  .catch((error) => console.error(error))

return purchaseDataset
