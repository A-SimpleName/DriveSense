import { Link} from 'react-router-dom';
import Logo from '/src/pics/DS_Logo.png';
import Einstellungen from '/src/pics/einstellungen.png';
import '/src/styles/topbar.css';

 
type TopbarProps = {
    onLogout: () => void;
};

function Topbar({ onLogout }: TopbarProps) {
    
    return (
        <nav className='topbar'>
            <Link to="/"><img src={Logo} alt="Logo" className="logo" width={200}/></Link>
            <Link to="/fahrten" className='rides'>Fahrten</Link>
            <Link to="/vehicles">Fahrzeuge</Link>
            <Link to="/einstellungen"><img src={Einstellungen} alt="Einstellungen" width={30} height={30}/></Link>
            <button onClick={onLogout}>Logout</button>
        </nav>
    );
}

export default Topbar;