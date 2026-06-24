import { Link } from "react-router-dom";
import "../../styles/footer.css";
import Logo from '/src/pics/DS_Logo.png';

function Footer() {
    return (
        <footer>
            <div className="infos">
                <p className="copyright">
                    © {new Date().getFullYear()}
                    <img src={Logo} alt="DriveSense Logo" width={100} />
                </p>

                <div>
                    <h3>Kontakt:</h3>
                    <p>
                        E-Mail: <a href="mailto:at.drivesense@gmail.com">
                            at.drivesense@gmail.com
                        </a>
                    </p>
                </div>
            </div>

            <div className="links">
                <Link to="/impressum">Impressum</Link>
                <Link to="/datenschutz">Datenschutz</Link>
            </div>
        </footer>
    );
}

export default Footer;