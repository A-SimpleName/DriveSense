import { Link } from 'react-router-dom';
// import { logout } from "../../services/auth";
// import { useNavigate } from "react-router-dom";
import Logo from '/src/pics/DS_Logo.png';
// import Einstellungen from '/src/pics/einstellungen.png';
import '/src/styles/topbar.css';
import UserMenu from '../userMenu';

type TopbarProps = {
    setAccount: React.Dispatch<React.SetStateAction<any>>;
    account: any;
};

function Topbar({ setAccount, account }: TopbarProps) {
    return (
        <nav className='topbar'>
            <Link to="/"><img src={Logo} alt="Logo" className="logo" width={200}/></Link>
            <Link to="/trips" className='rides'>Fahrten</Link>
            <Link to="/vehicles">Fahrzeuge</Link>
            <Link to="/protocols">Protokolle</Link>
            <Link to="/groups">Gruppen</Link>
            <UserMenu setAccount={setAccount} account={account} />
        </nav>
    );
}

export default Topbar;