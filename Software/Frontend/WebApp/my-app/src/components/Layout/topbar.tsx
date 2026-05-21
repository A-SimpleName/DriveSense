import { Link } from 'react-router-dom';
import Logo from '/src/pics/DS_Logo.png';
import '/src/styles/topbar.css';
import UserMenu from '../userMenu';
import { useAuth } from '../../context/authContext';

function Topbar() {
    const { profile } = useAuth();
    return (
        <nav className='topbar'>
            <Link to="/">
                <img src={Logo} alt="Logo" className="logo" width={200}/>
            </Link>

            <Link to="/trips" className='rides'>Fahrten</Link>
            <Link to="/vehicles">Fahrzeuge</Link>
            <Link to="/protocols">Protokolle</Link>
            <Link to="/groups">Gruppen</Link>
            {profile?.role === "ADMIN" && (
                <Link to="/admin">Admin</Link>
            )}

            <UserMenu />
        </nav>
    );
}

export default Topbar;