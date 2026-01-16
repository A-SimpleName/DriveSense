import { Link } from 'react-router-dom';
import Logo from '/src/pics/DS_Logo.png';
import Einstellungen from '/src/pics/einstellungen.png';
import '/src/styles/topbar.css';
import { Button } from '../button';
 
function Topbar() {
    return (
        <nav className='topbar'>
            <Link to="/"><img src={Logo} alt="Logo" className="logo" width={200}/></Link>
            <Link to="/trips" className='rides'>Fahrten</Link>
            <Link to="/map">Karten</Link>
            <Link to="/vehicles">Fahrzeuge</Link>
            <Link to="/settings"><img src={Einstellungen} alt="Einstellungen" width={30} height={30}/></Link>
            <Link to="/login">
                <Button label="Logout"></Button>
            </Link>
        </nav>
    );
}

export default Topbar;