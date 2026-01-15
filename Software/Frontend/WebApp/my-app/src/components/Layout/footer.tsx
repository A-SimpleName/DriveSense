import { Link } from "react-router-dom";
import "../../styles/footer.css";

function Footer () {
    return (
        <footer>
            <div className="infos">
                <p>© 2024 DriveSense</p>
                <div>
                    <h3>Kontakt:</h3>
                    <p>Telefon: +43 123 456 789</p>
                    <p>email: drivesense@example.com</p>
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