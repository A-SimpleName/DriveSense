import { useState } from "react";
import GroupTable from "../components/group/table";
import { GroupAddForm } from "../components/group/groupAddForm";
import type { UserGroup } from "../model/usergroup";

function GroupPage() {
    const [showModal, setShowModal] = useState(false);
    const [newGroup, setNewGroup] = useState<UserGroup | null>(null);

    return (
        <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h1>Gruppenverwaltung</h1>
                <button onClick={() => setShowModal(true)}>Gruppe erstellen</button>
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