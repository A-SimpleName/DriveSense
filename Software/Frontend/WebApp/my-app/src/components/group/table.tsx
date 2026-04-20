import { useEffect, useState } from "react";
import { getGroups } from "../../services/groupService";
import type { UserGroup } from "../../model/usergroup";
import { useNavigate } from "react-router-dom";

function GroupTable() {
    const navigate = useNavigate()
    const [groups,setGroup] = useState<UserGroup[]>([])

    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    
    useEffect(() => {
        setLoading(true)
        getGroups()
            .then(data => setGroup(data))
            .catch(err => setError(err.message))
            .finally(() => setLoading(false))
    }, [])
    
    if (loading) return <p>Laden...</p>
    if (error) return <p>Fehler: {error}</p>
    return (
        <div>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Owner</th>
                    </tr>
                </thead>
                <tbody>
                    {groups.map(group => (
                        <tr key={group.id}
                            onClick={() => navigate(`/groups/${group.id}`)}
                            style={{ cursor: "pointer" }}
                        >
                            <td>{group.name}</td>
                            <td>{group.Owner}</td>
                        </tr>
                    ))}
                </tbody>    
            </table>
        </div>
    );
}

export default GroupTable;