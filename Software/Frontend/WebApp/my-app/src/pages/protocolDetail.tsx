import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import type { ProtocolDetail } from "../model/protocol";
import { getProtocolByIdWithTrips } from "../services/protocolService";
import ProtocolView from "../components/Protocols/protocolView";

export default function ProtocolDetailPage() {
    const { id } = useParams();
    const [protocol, setProtocol] = useState<ProtocolDetail | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const load = () => {
        if (!id) { setError("Keine ID vorhanden"); setLoading(false); return; }
        setLoading(true);
        setError(null);
        getProtocolByIdWithTrips(parseInt(id))
            .then(data => setProtocol(data))
            .catch(err => setError(err?.message || "Fehler beim Laden des Protokolls"))
            .finally(() => setLoading(false));
    };

    useEffect(() => { load(); }, [id]);

    if (loading) return <div>Lade Protokoll...</div>;

    if (error) return (
        <div>
            <p style={{ color: "#dc2626" }}>{error}</p>
            <button onClick={load}>Erneut versuchen</button>
        </div>
    );

    if (!protocol) return <div>Kein Protokoll gefunden</div>;

    const isGroup = protocol.usergroup?.id != null;

    switch (protocol.protocolRole) {
        case "FAHRSCHÜLER": return <ProtocolView protocol={protocol} type="FAHRSCHÜLER" isGroup={isGroup} />;
        case "PRIVAT":      return <ProtocolView protocol={protocol} type="PRIVAT"      isGroup={isGroup} />;
        case "BERUFSFAHRER":return <ProtocolView protocol={protocol} type="BERUFSFAHRER" isGroup={isGroup} />;
        default:            return <div>Unbekannte Rolle: {protocol.protocolRole}</div>;
    }
}