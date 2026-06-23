import { Link } from "react-router-dom";
import "../styles/legal.css";

function ImpressumPage() {
  return (
    <main className="legal-page">
      <article className="legal-document">
        <Link className="legal-back-link" to="/">
          Zurück zur App
        </Link>

        <header className="legal-header">
          <p className="legal-kicker">DriveSense</p>
          <h1>Impressum</h1>
        </header>

        <section>
          <h2>Medieninhaber und Betreiber</h2>
          <p>HTL Perg</p>
          <p>Machlandstraße 48</p>
          <p>4320 Perg</p>
          <p>Österreich</p>
        </section>

        <section>
          <h2>Kontakt</h2>
          <p>
            E-Mail:{" "}
            <a href="mailto:at.drivesense@gmail.com">
              at.drivesense@gmail.com
            </a>
          </p>
          <p>
            Telefon: <a href="tel:+43726252391">+43 7262 52391</a>
          </p>
        </section>

        <section>
          <h2>Verantwortlich für den Inhalt</h2>
          <p>Eric Hölzl (Projektleitung)</p>
          <p>HTL Perg</p>
          <p>Machlandstraße 48</p>
          <p>4320 Perg</p>
          <p>Österreich</p>
        </section>

        <section>
          <h2>Zweck des Mediums</h2>
          <p>
            DriveSense ist ein nicht-kommerzielles Schulprojekt und stellt eine Web-App zur digitalen
            Fahrtenaufzeichnung, Fahrzeugverwaltung und
            Fahrtenprotokollverwaltung bereit.
          </p>
        </section>

        <section>
          <h2>Datenschutz</h2>
          <p>
            Informationen zur Verarbeitung personenbezogener Daten finden Sie in
            der <Link to="/datenschutz">Datenschutzerklärung</Link>.
          </p>
        </section>
      </article>
    </main>
  );
}

export default ImpressumPage;
