import { Link, useLocation } from 'react-router-dom';
import Logo from '/src/pics/DS_Logo.png';
import '/src/styles/topbar.css';
import UserMenu from '../userMenu';

function Topbar() {
    const location = useLocation();

    const isActive = (path: string) => {
        return location.pathname === path || location.pathname.startsWith(path + '/');
    };

    return (
        <nav className='topbar'>
            <Link to="/">
                <img src={Logo} alt="Logo" className="logo" width={200}/>
            </Link>

            <Link to="/trips" className={isActive('/trips') ? 'nav-link active' : 'nav-link'}>Fahrten</Link>
            <Link to="/vehicles" className={isActive('/vehicles') ? 'nav-link active' : 'nav-link'}>Fahrzeuge</Link>
            <Link to="/protocols" className={isActive('/protocols') ? 'nav-link active' : 'nav-link'}>Protokolle</Link>
            <Link to="/groups" className={isActive('/groups') ? 'nav-link active' : 'nav-link'}>Gruppen</Link>

            <UserMenu />
        </nav>
    );
}

export default Topbar;
