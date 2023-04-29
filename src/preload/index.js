import { address } from 'ip'
import { uptime, userInfo, release } from 'os'

function secondsToTimestamp() {
  const seconds = uptime()
  let hours = Math.floor(seconds / 3600)
  let minutes = Math.floor((seconds % 3600) / 60)

  hours = hours < 10 ? '0' + hours : hours
  minutes = minutes < 10 ? '0' + minutes : minutes

  return `${hours}h ${minutes}m`
}

window.addEventListener('DOMContentLoaded', () => {
  const setInnerHtml = async () => {
    document.getElementById('ip-address').innerHTML = address()
    document.getElementById('computer-name').innerHTML = userInfo().username
    document.getElementById('os-version').innerHTML = release()
    document.getElementById('last-restart').innerHTML = secondsToTimestamp()
  }

  setInnerHtml()
})
