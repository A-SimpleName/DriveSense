import type { Protocol } from "../../model/protocol";

export default function ProtocolTable({ ownProtocols, groupProtocols }: { ownProtocols: Protocol[], groupProtocols: Protocol[] }) {
    return (
        <div>
            <h3>Eigene Protokolle</h3>
            <table>
                <tbody>
                    {ownProtocols.map(protocol => (
                        <tr key={protocol.id}>
                            <td>{protocol.name}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
            <h3>Gruppenprotokolle</h3>
            <table>
                <tbody> 
                    {groupProtocols.map(protocol => (
                        <tr key={protocol.id}>
                            <td>{protocol.name}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
