import { Link } from "react-router-dom";
import "../styles/legal.css";

const dataCategories = [
  "Accountdaten: Vorname, Nachname, E-Mail-Adresse, Passwort-Hash, Verifizierungsstatus, optionales Geburtsdatum, Erstellungs- und Löschzeitpunkte.",
  "Profildaten: Profilname, Rolle und Zuordnung zum Account.",
  "Fahrzeugdaten: Modell, Kennzeichen, Kilometerstand, Rollen und Zuordnungen zu Profilen.",
  "Fahrtdaten: Start- und Endzeit, Strecke, Kilometerstände, Start-, Ziel- und entferntester Punkt, Fahrbahnbedingungen, Fahrtart sowie Momentaufnahmen von Fahrzeug, Kennzeichen und Profilname.",
  "Standort- und Bewegungsdaten: GPS-Koordinaten, Genauigkeit, Geschwindigkeit, Richtung und Zeitstempel der Trackingpunkte während einer aufgezeichneten Fahrt.",
  "Gruppen-, Protokoll- und Einladungsdaten: Gruppenname, Mitgliederrollen, Protokollname, eingeladene Accounts, einladende Profile, Einladungscodes als Hash, Status und Ablaufzeitpunkte.",
  "Sicherheits- und Kommunikationsdaten: E-Mail-Verifizierungscodes und Passwort-Zurücksetzen-Codes jeweils als Hash, Ablaufzeitpunkt und Nutzungsstatus.",
];

const rights = [
  "Auskunft über die gespeicherten personenbezogenen Daten",
  "Berichtigung unrichtiger Daten",
  "Löschung oder Einschränkung der Verarbeitung",
  "Datenübertragbarkeit, soweit technisch und rechtlich anwendbar",
  "Widerspruch gegen Verarbeitungen auf Grundlage berechtigter Interessen",
  "Beschwerde bei der zuständigen Datenschutzaufsichtsbehörde",
];

function DatenschutzPage() {
  return (
    <main className="legal-page">
      <article className="legal-document">
        <Link className="legal-back-link" to="/">
          Zurück zur App
        </Link>

        <header className="legal-header">
          <p className="legal-kicker">DriveSense</p>
          <h1>Datenschutzerklärung</h1>
          <p>
            Diese Datenschutzerklärung informiert darüber, welche
            personenbezogenen Daten DriveSense verarbeitet, wenn die Web-App
            oder App zur Fahrtenprotokollierung genutzt wird.
          </p>
        </header>

        <section>
          <h2>1. Verantwortlicher und Kontakt</h2>
          <p>
            Verantwortlich für die Datenverarbeitung ist DriveSense. Fragen zum
            Datenschutz können per E-Mail an{" "}
            <a href="mailto:at.drivesense@gmail.com">
              at.drivesense@gmail.com
            </a>{" "}
            gerichtet werden.
          </p>
        </section>

        <section>
          <h2>2. Verarbeitete personenbezogene Daten</h2>
          <p>
            DriveSense verarbeitet nur Daten, die für Registrierung, Anmeldung,
            Profilverwaltung, Fahrzeugverwaltung, Fahrtenaufzeichnung,
            Fahrtenprotokolle, Gruppenfunktionen, Einladungen und
            Sicherheitsfunktionen erforderlich sind.
          </p>
          <ul>
            {dataCategories.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section>
          <h2>3. Zwecke der Verarbeitung</h2>
          <p>
            Die Daten werden verwendet, um Accounts bereitzustellen, Nutzer zu
            authentifizieren, Profile und Rollen zu verwalten, Fahrzeuge und
            Gruppen zu organisieren, Fahrten mit Standortpunkten aufzuzeichnen,
            Fahrtenprotokolle zu erstellen, PDF-Exporte zu ermöglichen,
            Einladungen zu versenden und Missbrauch zu verhindern.
          </p>
        </section>

        <section>
          <h2>4. Rechtsgrundlagen</h2>
          <p>
            Die Verarbeitung erfolgt, soweit sie für die Nutzung von DriveSense
            notwendig ist, auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO.
            Sicherheitsrelevante Verarbeitungen, Protokollierung und
            Missbrauchsschutz erfolgen auf Grundlage von Art. 6 Abs. 1 lit. f
            DSGVO. Soweit gesetzliche Aufbewahrungspflichten bestehen, erfolgt
            die Verarbeitung auf Grundlage von Art. 6 Abs. 1 lit. c DSGVO.
          </p>
        </section>

        <section>
          <h2>5. Standortdaten und Fahrtenaufzeichnung</h2>
          <p>
            Standortdaten werden nur im Zusammenhang mit einer aufgezeichneten
            Fahrt verarbeitet. Dabei werden Koordinaten, Genauigkeit,
            Geschwindigkeit, Richtung und Zeitstempel gespeichert, um die Fahrt
            nachvollziehbar zu dokumentieren. Ohne diese Daten kann die
            automatische Fahrtenprotokollierung nicht vollständig genutzt
            werden.
          </p>
        </section>

        <section>
          <h2>6. Empfänger und externe Dienste</h2>
          <p>
            Innerhalb von DriveSense erhalten nur berechtigte Nutzer Zugriff auf
            Daten, etwa Mitglieder gemeinsamer Gruppen oder berechtigte
            Fahrzeugnutzer entsprechend ihrer Rolle. Für Funktionen wie
            Geocoding, Karten, E-Mail-Versand oder Fahrbahn-/Wetterdaten können
            technische Dienstleister eingebunden werden. An diese Dienste werden
            nur die Daten übermittelt, die für die jeweilige Funktion
            erforderlich sind.
          </p>
        </section>

        <section>
          <h2>7. Speicherdauer und Löschung</h2>
          <p>
            Daten werden gespeichert, solange sie für die Nutzung des Accounts
            und die Fahrtenprotokollierung erforderlich sind. Nicht verifizierte
            Accounts können automatisch gelöscht werden. Tokens für
            E-Mail-Verifizierung, Passwort-Zurücksetzung und Einladungen haben
            Ablaufzeitpunkte. Beim Löschen von Accounts, Profilen, Fahrzeugen,
            Gruppen, Protokollen oder Fahrten werden Daten je nach technischer
            und rechtlicher Notwendigkeit gelöscht, anonymisiert oder mit
            Löschzeitpunkt gesperrt.
          </p>
        </section>

        <section>
          <h2>8. Sicherheit</h2>
          <p>
            Passwörter, Verifizierungs-, Einladungs- und
            Passwort-Zurücksetzen-Codes werden nicht im Klartext gespeichert,
            sondern als Hash. Der Zugriff auf geschützte Bereiche erfolgt über
            Authentifizierungstokens und rollenbasierte Berechtigungen.
          </p>
        </section>

        <section>
          <h2>9. Betroffenenrechte</h2>
          <p>
            Betroffene Personen haben nach Maßgabe der DSGVO insbesondere
            folgende Rechte:
          </p>
          <ul>
            {rights.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
          <p>
            Anfragen können an{" "}
            <a href="mailto:at.drivesense@gmail.com">
              at.drivesense@gmail.com
            </a>{" "}
            gesendet werden.
          </p>
        </section>

        <section>
          <h2>10. Aktualität</h2>
          <p>
            Diese Datenschutzerklärung kann angepasst werden, wenn sich
            Funktionen, Datenverarbeitungen oder rechtliche Anforderungen
            ändern.
          </p>
        </section>
      </article>
    </main>
  );
}

export default DatenschutzPage;
