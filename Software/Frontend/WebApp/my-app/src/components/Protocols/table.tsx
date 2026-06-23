import type { Protocol } from "../../model/protocol";
import { useNavigate } from "react-router-dom"
import { Button } from "../button";
import { exportProtocol, deleteProtocol } from "../../services/protocolService";
import { useState } from "react";
import { ConfirmationDialog } from "../ConfirmationDialog";
import { Plus, Download, Trash2 } from "lucide-react";
import "../../styles/pageLayout.css";

export default function ProtocolTable({ ownProtocols, groupProtocols, setShowForm, onDeleted }: {
    ownProtocols: Protocol[];
    groupProtocols: Protocol[];
    setShowForm: (open: boolean) => void;
    onDeleted: () => void;
}) {
    const navigate = useNavigate();
    const [error, setError] = useState<string | null>(null);
    const [exportError, setExportError] = useState<string | null>(null);
    const [exportingId, setExportingId] = useState<number | null>(null);
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);

    const handleExport = async (id: number) => {
        setExportError(null);
        setExportingId(id);
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
            setExportError(err?.message || "Export fehlgeschlagen");
        } finally {
            setExportingId(null);
        }
    };

    const handleDelete = (id: number) => {
        setError(null);
        deleteProtocol(id)
            .then(() => onDeleted())
            .catch(err => setError(err?.message || "Löschen fehlgeschlagen"));
    };

    const confirmDelete = () => {
        if (confirmDeleteId === null) return;
        handleDelete(confirmDeleteId);
        setConfirmDeleteId(null);
    };

    const renderTable = (protocols: Protocol[], title: string, showAdd: boolean = true) => (
        <div style={{ marginBottom: "2rem" }}>
            <div className="page-toolbar">
                <span className="page-toolbar-left" style={{ fontSize: "14px", fontWeight: 500 }}>{title}</span>
                <div className="page-toolbar-right">
                    <span style={{ fontSize: "13px", color: "var(--color-text-secondary)" }}>
                        {protocols.length} {protocols.length === 1 ? "Protokoll" : "Protokolle"}
                    </span>
                    {showAdd && (
                        <Button label="" className="small icon" title="Protokoll hinzufügen" onClick={() => setShowForm(true)} icon={<Plus size={18} />} />
                    )}
                </div>
            </div>
            <table style={{ width: "100%" }}>
                <thead>
                    <tr>
                        <th style={{ textAlign: "left", width: "40%" }}>Name</th>
                        <th style={{ textAlign: "center", width: "60%" }}>Aktion</th>
                    </tr>
                </thead>
                <tbody>
                    {protocols.map(protocol => (
                        <tr key={protocol.id} onClick={() => navigate(`/protocols/${protocol.id}`)} style={{ cursor: "pointer" }}>
                            <td>{protocol.name}</td>
                            <td style={{ display: "flex", justifyContent: "center", gap: "8px" }}>
                                <Button label={exportingId === protocol.id ? "Exportiert..." : "Exportieren"} loading={exportingId === protocol.id} stopPropagation onClick={() => handleExport(protocol.id)} icon={<Download size={18} />} />
                                <Button label="Löschen" stopPropagation onClick={() => setConfirmDeleteId(protocol.id)} icon={<Trash2 size={18} />} />
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );

    return (
        <div>
            {/* Getrennte Fehlermeldungen für Export und Löschen */}
            {exportError && <p className="error-text" style={{ marginBottom: "8px" }}>{exportError}</p>}
            {error && <p className="error-text" style={{ marginBottom: "8px" }}>{error}</p>}

            {renderTable(ownProtocols, "Eigene Protokolle",true)}
            {renderTable(groupProtocols, "Gruppenprotokolle",false)}

            <ConfirmationDialog
                open={confirmDeleteId !== null}
                title="Protokoll löschen"
                message="Möchtest du dieses Protokoll wirklich unwiderruflich löschen?"
                confirmLabel="Ja, löschen"
                cancelLabel="Abbrechen"
                onConfirm={confirmDelete}
                onCancel={() => setConfirmDeleteId(null)}
            />
        </div>
    );
}