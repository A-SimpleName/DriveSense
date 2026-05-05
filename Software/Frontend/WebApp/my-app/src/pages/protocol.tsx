import { useEffect, useState } from "react";
import { getAllProtocols } from "../services/protocolService";
import type { Protocol } from "../model/protocol";
// import { useParams } from "react-router-dom";
// import { getGroups } from "../services/groupService";
// import type { UserGroup } from "../model/usergroup";
import ProtocolTable from "../components/Protocols/table";

export default function ProtocolPage() {
    // const { id } = useParams();
    // const [groups, setGroups] = useState<UserGroup[]>([]);
    const [protocols, setProtocols] = useState<Protocol[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);


    // 1. Gruppen laden
    // 2. Protokoll aus allen group Ids Laden
    // 3. Protokoll des eigenen Profiles laden

    // useEffect(() => {
    //         if (!id) return;
    //         getGroups()
    //             .then(data => setGroups([...data]))
    //             .catch(err => setError(err.message))
    //     }, [id]);

    // groups.forEach(group => {
    //     useEffect(() => {
    //         if (!id) return;
    //         getProtocolById(group.id)
    //             .then(data => setProtocols(prev => [...prev, data]))
    //             .catch(err => setError(err.message))
    //             .finally(() => setLoading(false));
    //     }, [group.id]);
    // });

    // oder gleich getAllByProfileId in ProtocolDao im Backend aufrufen
    useEffect(() => {
        getAllProtocols()
            .then(data => {
                const sorted = [...data].sort((a, b) => {
                    // Erst: null usergroup_id zuerst
                    if (a.usergroup.id === null && b.usergroup.id !== null) return -1;
                    if (a.usergroup.id !== null && b.usergroup.id === null) return 1;

                    // Dann: nach createdAt absteigend (neueste zuerst)
                    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
                });
                setProtocols(sorted);
            })
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    const groupProtocols = protocols.filter(p => p.usergroup?.id !== null);
    const ownProtocols = protocols.filter(p => p.usergroup.id === null);

    if (loading) return <div>Lade Protokolle...</div>;

    if (error) return <div>{error}</div>;

    return (
        <div>
            <h2> Protokolle</h2>
            <ProtocolTable ownProtocols={ownProtocols} groupProtocols={groupProtocols} />
        </div>
    );
}