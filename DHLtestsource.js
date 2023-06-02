// This example shows how to make a call to an open API (no authentication required)
// to retrieve asset price from a symbol(e.g., ETH) to another symbol (e.g., USD)

// Arguments can be provided when a request is initated on-chain and used in the request source code as shown below
const trackingNumber = args[0]

// make HTTP request
const url = "https://api-eu.dhl.com/track/shipments?trackingNumber="
console.log(`HTTP GET Request to ${url}${trackingNumber}...`)

// construct the HTTP Request object. See: https://github.com/smartcontractkit/functions-hardhat-starter-kit#javascript-code
// params used for URL query parameters
// Example of query: https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD
const trackingRequest = Functions.makeHttpRequest({
  url: url + trackingNumber,
  method: "GET",
  headers: {
    Accept: "application/json",
    "DHL-API-Key": secrets.dhlKey,
  },
})

// Execute the API request (Promise)
const trackingResponse = await trackingRequest
if (trackingResponse.error) {
  console.error(trackingResponse.error)
  throw Error("Request failed")
}

const trackingData = trackingResponse["data"]
if (trackingData.Response === "Error") {
  console.error(trackingData.Message)
  throw error(`Functional error. Read message: ${trackingData.Message}`)
}

const currentLocation = trackingData["shipments"][0]["status"]["location"]["address"]["addressLocality"]

console.log(`Current location of tracked entity: ${currentLocation}`)

return Functions.encodeString(`${currentLocation}`)
