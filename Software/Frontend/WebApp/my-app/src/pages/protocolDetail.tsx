import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import type { Protocol } from "../model/protocol";
import { getProtocolById } from "../services/protocolService";
import ProtocolView from "../components/Protocols/protocolView";

export default function ProtocolDetail() {
    const { id } = useParams();

    const [protocol, setProtocol] = useState<Protocol | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (!id) {
            setError("Keine ID vorhanden");
            setLoading(false);
            return;
        }

        setLoading(true);
        setError(null);

        getProtocolById(parseInt(id!))
            .then(data => setProtocol(data))
            .catch(err => {
                console.error(err);
                setError("Fehler beim Laden des Protokolls");
            })
            .finally(() => setLoading(false));
    }, [id]);

    if (loading) return <div>Lade Protokoll...</div>;

    if (error) return <div>{error}</div>;

    if (!protocol) return <div>Kein Protokoll gefunden</div>;

    const isGroup = protocol.usergroup.id != null;

    switch (`${protocol.protocolRole}`) {
        case "FAHRSCHÜLER":
            return <ProtocolView protocol={protocol} type="FAHRSCHÜLER" isGroup={isGroup} />;

        case "PRIVAT":
            return <ProtocolView protocol={protocol} type="PRIVAT" isGroup={isGroup} />;

        case "BERUFSFAHRER_SINGLE":
            return <ProtocolView protocol={protocol} type="BERUFSFAHRER" isGroup={isGroup} />;

        default:
            return <div>Unbekannte Rolle</div>;
    }
}