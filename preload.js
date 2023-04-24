const ip = require("ip");
// All the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.
window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('ip-address').innerHTML = ip.address();
})