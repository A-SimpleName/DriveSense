import { useEffect, useState } from "react";
import { getAllProtocols } from "../services/protocolService";
import type { Protocol } from "../model/protocol";
import ProtocolTable from "../components/Protocols/table";
import { ProtocolAddForm } from "../components/Protocols/protocolAddForm";
import { Button } from "../components/button";

export default function ProtocolPage() {
    const [protocols, setProtocols] = useState<Protocol[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [showForm, setShowForm] = useState(false);
    const [reloadKey, setReloadKey] = useState(0);

    useEffect(() => {
        getAllProtocols()
            .then(data => {
                const sorted = [...data].sort((a, b) => {

                    // Erst: null usergroup_id zuerst
                    if (a.usergroupId === null && b.usergroupId !== null) return -1;
                    if (a.usergroupId !== null && b.usergroupId === null) return 1;

                    // Dann: nach createdAt absteigend (neueste zuerst)
                    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
                });
                setProtocols(sorted);
            })
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, [reloadKey]);

    console.log("Protocols:", protocols);

    const groupProtocols = protocols.filter(p => p.usergroupId != null);
    const ownProtocols = protocols.filter(p => p.usergroupId == null);

    if (loading) return <div>Lade Protokolle...</div>;

    if (error) return <div>{error}</div>;

    return (
        <div>
            <Button
                label="+ Protokoll hinzufügen"
                onClick={() => setShowForm(true)}
            />

            {
                showForm && (
                    <ProtocolAddForm
                        onClose={() => setShowForm(false)}
                        onSuccess={() => setReloadKey(prev => prev + 1)}
                        usergroupId={null}
                    />
                )
            }
            <h2> Protokolle</h2>
            <ProtocolTable ownProtocols={ownProtocols} groupProtocols={groupProtocols} />
        </div>
    );
}