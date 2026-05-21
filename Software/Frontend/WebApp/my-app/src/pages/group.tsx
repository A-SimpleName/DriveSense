import { useState } from "react";
import GroupTable from "../components/group/table";
import { GroupAddForm } from "../components/group/groupAddForm";
import type { UserGroup } from "../model/usergroup";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/button";

function GroupPage() {
    const navigate = useNavigate();
    const [showModal, setShowModal] = useState(false);
    const [newGroup, setNewGroup] = useState<UserGroup | null>(null);

    return (
        <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h1>Gruppenverwaltung</h1>
                <button onClick={() => navigate("/invite")}>Gruppeneinladung annehmen</button>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '10px' }}>
                <Button label="+" className="small icon" title="Gruppe erstellen" onClick={() => setShowModal(true)} />
            </div>

            <GroupTable newGroup={newGroup} />

            {showModal && (
                <div
                    onClick={() => setShowModal(false)}
                    style={{
                        position: "fixed", inset: 0,
                        background: "rgba(0,0,0,0.4)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        zIndex: 100,
                    }}
                >
                    <div onClick={e => e.stopPropagation()}>
                        <GroupAddForm
                            onClose={() => setShowModal(false)}
                            onCreated={(group) => {
                                setNewGroup(group);
                                setShowModal(false);
                            }}
                        />
                    </div>
                </div>
            )}
        </div>
    );
}

export default GroupPage;