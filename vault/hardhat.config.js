require('dotenv').config()
require('@nomiclabs/hardhat-ethers')
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  networks: {
    testnet: {
      url: process.env.NODE_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.6.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100
          }
        }
      },
    ]
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
}
RnJvbSA3YzhjN2JkNGI2MDJjOWE2NjZhM2U5Mzc5YmYyOGZhMjg1NGE2Zjc4IE1vbiBTZXAgMTcgMDA6MDA6MDAgMjAwMQpGcm9tOiBZaW5nIFdhbmcgPHdhbmd5aW5nQGdvb2dsZS5jb20+CkRhdGU6IFdlZCwgMDQgRGVjIDIwMTMgMTY6MDQ6NDkgLTA4MDAKU3ViamVjdDogW1BBVENIXSBBZGQgdXRpbGl0eSBmdW5jdGlvbiBmaW5kLWZpbGVzLWluLXN1YmRpcnMKCmZpbmQtZmlsZXMtaW4tc3ViZGlycyB1c2VzIHV0aWxpdHkgZmluZCB0byBmaW5kIGdpdmVuIGZpbGVzIGluIHRoZSBnaXZlbgpzdWJkaXJzLiBUaGlzIGZ1bmN0aW9uIHVzZXMgJCgxKSwgaW5zdGVhZCBvZiBMT0NBTF9QQVRIIGFzIHRoZSBiYXNlLgoKQ2hhbmdlLUlkOiBJYjc2NjMxYzk3YWNkMjU3ZDY1MWE1ODBjYmFkNzY3NjA2ODc0ZjVkMAotLS0KCmRpZmYgLS1naXQgYS9jb3JlL2RlZmluaXRpb25zLm1rIGIvY29yZS9kZWZpbml0aW9ucy5tawppbmRleCAyOTBiYjJmLi5lMWViOWYxIDEwMDY0NAotLS0gYS9jb3JlL2RlZmluaXRpb25zLm1rCisrKyBiL2NvcmUvZGVmaW5pdGlvbnMubWsKQEAgLTM0Miw2ICszNDIsMjIgQEAKIGVuZGVmCiAKICMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCisjIFVzZSB1dGlsaXR5IGZpbmQgdG8gZmluZCBnaXZlbiBmaWxlcyBpbiB0aGUgZ2l2ZW4gc3ViZGlycy4KKyMgVGhpcyBmdW5jdGlvbiB1c2VzICQoMSksIGluc3RlYWQgb2YgTE9DQUxfUEFUSCBhcyB0aGUgYmFzZS4KKyMgJCgxKTogdGhlIGJhc2UgZGlyLCByZWxhdGl2ZSB0byB0aGUgcm9vdCBvZiB0aGUgc291cmNlIHRyZWUuCisjICQoMik6IHRoZSBmaWxlIG5hbWUgcGF0dGVybiB0byBiZSBwYXNzZWQgdG8gZmluZCBhcyAiLW5hbWUiLgorIyAkKDMpOiBhIGxpc3Qgb2Ygc3ViZGlycyBvZiB0aGUgYmFzZSBkaXIuCisjIFJldHVybnM6IGEgbGlzdCBvZiBwYXRocyByZWxhdGl2ZSB0byB0aGUgYmFzZSBkaXIuCisjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIworCitkZWZpbmUgZmluZC1maWxlcy1pbi1zdWJkaXJzCiskKHBhdHN1YnN0IC4vJSwlLCBcCisgICQoc2hlbGwgY2QgJCgxKSA7IFwKKyAgICAgICAgICBmaW5kIC1MICQoMykgLW5hbWUgJCgyKSAtYW5kIC1ub3QgLW5hbWUgIi4qIikgXAorICkKK2VuZGVmCisKKyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiAjIyBTY2FuIHRocm91Z2ggZWFjaCBkaXJlY3Rvcnkgb2YgJCgxKSBsb29raW5nIGZvciBmaWxlcwogIyMgdGhhdCBtYXRjaCAkKDIpIHVzaW5nICQod2lsZGNhcmQpLiAgVXNlZnVsIGZvciBzZWVpbmcgaWYKICMjIGEgZ2l2ZW4gZGlyZWN0b3J5IG9yIG9uZSBvZiBpdHMgcGFyZW50cyBjb250YWlucwo=