import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import type { GroupMember } from "../model/usergroup";
import { getGroupMembers } from "../services/groupService";

function GroupDetailPage() {
    const { id } = useParams();
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [members, setMembers] = useState<GroupMember[]>([]);

    useEffect(() => {
            setLoading(true)
            getGroupMembers(Number(id))
                .then(data => setMembers(data))
                .catch(err => setError(err.message))
                .finally(() => setLoading(false))
        }, [id])
    
    if (loading) return <p>Laden...</p>
    if (error) return <p>Fehler: {error}</p>

    return ( 
        <div>
            <h2>Gruppenmitglieder</h2>
            <ul>
                {members.map(member => (
                    <li key={member.profileId}>
                        {member.name} - {member.groupRole}
                    </li>
                ))}
            </ul>
        </div> 
    );
}

export default GroupDetailPage;