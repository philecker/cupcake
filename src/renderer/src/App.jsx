import copyIcon from './assets/copy.png'
import store  from 'store'

const systemDetails = store.get('cupcakeInfo');
console.log(systemDetails);

function App() {
  return (
    <ul id="itemsList">
      <li>
        <div className="cupcake-label">
          Internal IP: <img className="copyIcon" src={copyIcon} />
          <span id="ip-address">{ systemDetails.cupcakeIp }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Username: <img className="copyIcon" src={copyIcon} />
          <span id="computer-name">{ systemDetails.cupcakeUsername }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          OS Version: <img className="copyIcon" src={copyIcon} />
          <span id="os-version">{ systemDetails.cupcakeOsVersion }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Last Restart: <img className="copyIcon" src={copyIcon} />
          <span id="last-restart">{ systemDetails.cupcakeUptime }</span>
        </div>
      </li>
    </ul>
  )
}

export default App
