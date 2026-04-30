import type { Protocol } from "../../model/protocol";
import { useNavigate } from "react-router-dom"
import { Button } from "../button";
import { exportProtocol } from "../../services/protocolService";
import { useState } from "react";

export default function ProtocolTable({ ownProtocols, groupProtocols, }: { ownProtocols: Protocol[], groupProtocols: Protocol[] }) {
    const navigate = useNavigate();
    const [error, setError] = useState<string | null>(null)

    const handleExport = async (id: number) => {
        try {
            const { blob, filename } = await exportProtocol(id);

            const url = window.URL.createObjectURL(blob);
            const a = document.createElement("a");

            a.href = url;
            a.download = filename ?? `protocol_${id}.pdf`;

            document.body.appendChild(a);
            a.click();

            a.remove();
            window.URL.revokeObjectURL(url);
        } catch (err: any) {
            setError(err.message);
        }
    };

    if (error) return <div>Fehler: {error}</div>;
    return (
        <div>
            <h3>Eigene Protokolle</h3>
            <table>
                <tbody>
                    {ownProtocols.map(protocol => (
                        <tr key={protocol.id}
                            onClick={() => navigate(`/protocols/${protocol.id}`)}
                            style={{ cursor: "pointer" }}
                        >       
                            <td>{protocol.name}</td>
                            <td><Button label="Exportieren" stopPropagation={true} onClick={() => handleExport(protocol.id)} /></td>
                        </tr>
                    ))}
                </tbody>
            </table>
            <h3>Gruppenprotokolle</h3>
            <table>
                <tbody> 
                    {groupProtocols.map(protocol => (
                        <tr key={protocol.id}
                            onClick={() => navigate(`/protocols/${protocol.id}`)}
                            style={{ cursor: "pointer" }}
                        >
                            <td>{protocol.name}</td>
                            <td><Button label="Exportieren" stopPropagation={true} onClick={() => handleExport(protocol.id)} /></td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
