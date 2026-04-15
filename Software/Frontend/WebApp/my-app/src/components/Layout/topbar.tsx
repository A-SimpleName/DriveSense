import { Link } from 'react-router-dom';
import { logout } from "../../services/auth";
import { useNavigate } from "react-router-dom";
import Logo from '/src/pics/DS_Logo.png';
import Einstellungen from '/src/pics/einstellungen.png';
import '/src/styles/topbar.css';

type TopbarProps = {
    setUser: React.Dispatch<React.SetStateAction<any>>;
};

function Topbar({ setUser }: TopbarProps) {
    const navigate = useNavigate(); 
    return (
        <nav className='topbar'>
            <Link to="/"><img src={Logo} alt="Logo" className="logo" width={200}/></Link>
            <Link to="/trips" className='rides'>Fahrten</Link>
            <Link to="/vehicles">Fahrzeuge</Link>
            <Link to="/protocols">Protokolle</Link>
            <Link to="/settings"><img src={Einstellungen} alt="Settings" width={30} height={30}/></Link>
            <button onClick={async () => {
                await logout();
                setUser(null);
                navigate("/login");
            }}>Logout</button>
        </nav>
    );
}

export default Topbar;