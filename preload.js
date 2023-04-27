const ip = require("ip");
const os = require("os");

// All the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.

function secondsToTimestamp() {
  const seconds = os.uptime();
  let hours = Math.floor(seconds / 3600);
  let minutes = Math.floor((seconds % 3600) / 60);
  let remainingSeconds = seconds % 60;

  hours = hours < 10 ? "0" + hours : hours;
  minutes = minutes < 10 ? "0" + minutes : minutes;
  remainingSeconds = remainingSeconds < 10 ? "0" + remainingSeconds : remainingSeconds;

  return `${hours}h ${minutes}m`;
}

window.addEventListener('DOMContentLoaded', () => {
  const setInnerHtml = async () => {
    // do something else here after firstFunction completes
    document.getElementById('ip-address').innerHTML = ip.address();
    document.getElementById('computer-name').innerHTML = os.userInfo().username;
    document.getElementById('os-version').innerHTML = os.release();
    document.getElementById('last-restart').innerHTML = secondsToTimestamp();
  }

  setInnerHtml();
});