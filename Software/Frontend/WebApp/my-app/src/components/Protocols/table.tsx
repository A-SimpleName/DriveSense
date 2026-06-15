import type { Protocol } from "../../model/protocol";
import { useNavigate } from "react-router-dom"
import { Button } from "../button";
import { exportProtocol, deleteProtocol } from "../../services/protocolService";
import { useState } from "react";
import { ConfirmationDialog } from "../ConfirmationDialog";

export default function ProtocolTable({ ownProtocols, groupProtocols, setShowForm, onDeleted }: { ownProtocols: Protocol[], groupProtocols: Protocol[], setShowForm: (open: boolean) => void, onDeleted?: () => void }) {
    const navigate = useNavigate();
    const [error, setError] = useState<string | null>(null)
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null)

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

    const handleDelete = (id: number) => {
        deleteProtocol(id)
            .then(() => {
                onDeleted?.();
            })
            .catch(err => setError(err.message))
    }

    const confirmDelete = () => {
        if (confirmDeleteId === null) return
        handleDelete(confirmDeleteId)
        setConfirmDeleteId(null)
    }

    const closeConfirm = () => setConfirmDeleteId(null)

    if (error) return <div>Fehler: {error}</div>;
    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                <h3 style={{ margin: 0 }}>Eigene Protokolle</h3>
                <Button
                    label="+"
                    className="small icon"
                    title="Protokoll hinzufügen"
                    onClick={() => setShowForm(true)}
                />
            </div>
            <table style={{ width: '100%' }}>
                <thead>
                    <tr>
                        <th style={{ textAlign: 'left', width: '40%' }}>Name</th>
                        <th style={{ textAlign: 'center', width: '60%' }}>Aktion</th>
                    </tr>
                </thead>
                <tbody>
                    {ownProtocols.map(protocol => (
                        <tr key={protocol.id}
                            onClick={() => navigate(`/protocols/${protocol.id}`)}
                            style={{ cursor: "pointer" }}
                        >       
                            <td>{protocol.name}</td>
                            <td style={{ textAlign: 'center' }}>
                                <Button label="Exportieren" stopPropagation={true} onClick={() => handleExport(protocol.id)} />
                                <Button label="Löschen" stopPropagation={true} onClick={() => setConfirmDeleteId(protocol.id)} />
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px', marginTop: '24px' }}>
                <h3 style={{ margin: 0 }}>Gruppenprotokolle</h3>
                <Button
                    label="+"
                    className="small icon"
                    title="Protokoll hinzufügen"
                    onClick={() => setShowForm(true)}
                />
            </div>
            <table style={{ width: '100%' }}>
                <thead>
                    <tr>
                        <th style={{ textAlign: 'left', width: '40%' }}>Name</th>
                        <th style={{ textAlign: 'center', width: '60%' }}>Aktion</th>
                    </tr>
                </thead>
                <tbody>
                    {groupProtocols.map(protocol => (
                        <tr key={protocol.id}
                            onClick={() => navigate(`/protocols/${protocol.id}`)}
                            style={{ cursor: "pointer" }}
                        >
                            <td>{protocol.name}</td>
                            <td style={{ textAlign: 'center' }}>
                                <Button label="Exportieren" stopPropagation={true} onClick={() => handleExport(protocol.id)} />
                                <Button label="Löschen" stopPropagation={true} onClick={() => setConfirmDeleteId(protocol.id)} />
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>

            <ConfirmationDialog
                open={confirmDeleteId !== null}
                title="Protokoll löschen"
                message="Möchtest du dieses Protokoll wirklich unwiderruflich löschen?"
                confirmLabel="Ja, löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={closeConfirm}
            />
        </div>
    );
}
