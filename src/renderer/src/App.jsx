import copyIcon from './assets/copy.png'
import { uptime, userInfo, release } from 'os'

function secondsToTimestamp() {
  const seconds = uptime()
  let hours = Math.floor(seconds / 3600)
  let minutes = Math.floor((seconds % 3600) / 60)

  hours = hours < 10 ? '0' + hours : hours
  minutes = minutes < 10 ? '0' + minutes : minutes

  return `${hours}h ${minutes}m`
}

function App() {
  return (
    <ul id="itemsList">
      <li>
        <div className="cupcake-label">
          Internal IP: <img className="copyIcon" src={copyIcon} />
          <span id="ip-address"></span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Username: <img className="copyIcon" src={copyIcon} />
          <span id="computer-name"></span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          OS Version: <img className="copyIcon" src={copyIcon} />
          <span id="os-version">{ release() }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Last Restart: <img className="copyIcon" src={copyIcon} />
          <span id="last-restart">{ secondsToTimestamp() }</span>
        </div>
      </li>
    </ul>
  )
}

export default App
