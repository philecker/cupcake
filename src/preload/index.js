import { address } from 'ip';
import { uptime, userInfo, release } from 'os'
import store from 'store'

const cupcakeUsername = userInfo().username;
const cupcakeOsVersion = release();
const cupcakeIp = address();
const cupcakeUptime = secondsToTimestamp();

function secondsToTimestamp() {
  const seconds = uptime()
  let hours = Math.floor(seconds / 3600)
  let minutes = Math.floor((seconds % 3600) / 60)

  hours = hours < 10 ? '0' + hours : hours
  minutes = minutes < 10 ? '0' + minutes : minutes

  return `${hours}h ${minutes}m`
}

store.set('cupcakeInfo', {
  cupcakeUsername,
  cupcakeOsVersion,
  cupcakeIp,
  cupcakeUptime
})