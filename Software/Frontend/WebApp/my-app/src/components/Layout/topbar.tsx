import { useEffect, useRef, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import Logo from '/src/pics/DS_Logo.png';
import '/src/styles/topbar.css';
import UserMenu from '../userMenu';

const NAV_ITEMS = [
    { to: '/', label: 'Dashboard' },
    { to: '/trips', label: 'Fahrten' },
    { to: '/vehicles', label: 'Fahrzeuge' },
    { to: '/protocols', label: 'Protokolle' },
    { to: '/groups', label: 'Gruppen' },
];

function Topbar() {
    const location = useLocation();
    const [menuOpen, setMenuOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);

    const isActive = (path: string) => {
        if (path === '/') return location.pathname === '/';
        return location.pathname === path || location.pathname.startsWith(path + '/');
    };

    // Menü beim Routenwechsel automatisch schließen
    useEffect(() => {
        setMenuOpen(false);
    }, [location.pathname]);

    // Klick außerhalb schließt das Menü, gleiches Pattern wie bei UserMenu
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setMenuOpen(false);
            }
        };

        if (menuOpen) {
            document.addEventListener('click', handleClickOutside);
        }

        return () => {
            document.removeEventListener('click', handleClickOutside);
        };
    }, [menuOpen]);

    return (
        <nav className='topbar'>
            <Link to="/" className="topbar-brand">
                <img src={Logo} alt="Logo" className="logo" width={200}/>
            </Link>

            <div className="topbar-links">
                {NAV_ITEMS.map(item => (
                    <Link
                        key={item.to}
                        to={item.to}
                        className={isActive(item.to) ? 'nav-link active' : 'nav-link'}
                    >
                        {item.label}
                    </Link>
                ))}
            </div>

            <div className="topbar-right">
                <UserMenu />

                <div className="topbar-burger-wrapper" ref={menuRef}>
                    <button
                        type="button"
                        className={`topbar-burger ${menuOpen ? 'is-open' : ''}`}
                        onClick={() => setMenuOpen(prev => !prev)}
                        aria-label={menuOpen ? 'Menü schließen' : 'Menü öffnen'}
                        aria-expanded={menuOpen}
                    >
                        <span></span>
                        <span></span>
                        <span></span>
                    </button>

                    {menuOpen && (
                        <div className="topbar-mobile-menu">
                            {NAV_ITEMS.map(item => (
                                <Link
                                    key={item.to}
                                    to={item.to}
                                    className={isActive(item.to) ? 'topbar-mobile-link active' : 'topbar-mobile-link'}
                                >
                                    {item.label}
                                </Link>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </nav>
    );
}

export default Topbar;