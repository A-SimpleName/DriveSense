import { useState } from "react";
import GroupTable from "../components/group/table";
import { GroupAddForm } from "../components/group/groupAddForm";
import type { UserGroup } from "../model/usergroup";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/button";
import "../styles/pageLayout.css";

function GroupPage() {
    const navigate = useNavigate();
    const [showModal, setShowModal] = useState(false);
    const [newGroup, setNewGroup] = useState<UserGroup | null>(null);

    return (
        <div>
            <div className="page-header">
                <h1>Gruppen</h1>
                <div className="page-header-actions">
                    <Button label="Einladung annehmen" onClick={() => navigate("/invite")} />
                    <Button label="Gruppe erstellen" title="Gruppe erstellen" onClick={() => setShowModal(true)} />
                </div>
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