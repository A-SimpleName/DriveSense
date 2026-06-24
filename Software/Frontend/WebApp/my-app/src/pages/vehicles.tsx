import { useState } from "react";
import { Button } from "../components/button";
import VehiclesTable from "../components/vehicles/table";
import { VehicleAddForm } from "../components/vehicles/vehicleAddForm";
import { acceptVehicleInvite } from "../services/vehicleService";
import { InviteCodeForm } from "../components/inviteCodeForm";
import { Mail, Plus } from "lucide-react";
import "../styles/pageLayout.css";

function Vehicles() {
    const [showForm, setShowForm] = useState(false);
    const [reloadKey, setReloadKey] = useState(0);
    const [acceptOpen, setAcceptOpen] = useState(false);

    return (
        <div>
            <div className="page-header">
                <h1>Fahrzeuge</h1>
                <div className="page-header-actions">
                    <Button label="Einladung annehmen" onClick={() => setAcceptOpen(true)} icon={<Mail size={18} />} />
                    <Button label="" className="small icon" title="Fahrzeug hinzufügen" onClick={() => setShowForm(true)} icon={<Plus size={18} />} />
                </div>
            </div>

            {acceptOpen && (
                <InviteCodeForm
                    title="Fahrzeug-Einladung annehmen"
                    placeholder="Link oder Code"
                    onVerify={async code => { await acceptVehicleInvite(code); }}
                    onSuccess={() => {
                        setAcceptOpen(false);
                        setReloadKey(prev => prev + 1);
                    }}
                    onClose={() => setAcceptOpen(false)}
                />
            )}

            {showForm && (
                <VehicleAddForm
                    onClose={() => setShowForm(false)}
                    onSuccess={() => setReloadKey(prev => prev + 1)}
                />
            )}

            <VehiclesTable key={reloadKey} />
        </div>
    );
}

export default Vehicles;
