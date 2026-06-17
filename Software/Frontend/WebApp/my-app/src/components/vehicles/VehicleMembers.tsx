import { useEffect, useState } from "react"
import { createPortal } from "react-dom"
import { getVehicleMembers, removeVehicleMember } from "../../services/vehicleService"
import { Button } from "../button"
import { ConfirmationDialog } from "../ConfirmationDialog"
import type { Vehicle, VehicleMember } from "../../model/vehicle"

interface Props {
    vehicle: Vehicle
    onClose: () => void
}

export function VehicleMembers({ vehicle, onClose }: Props) {
    const [members, setMembers] = useState<VehicleMember[]>([])
    const [loading, setLoading] = useState(false)
    const [loadError, setLoadError] = useState<string | null>(null)
    const [removeError, setRemoveError] = useState<string | null>(null)
    const [confirmRemoveId, setConfirmRemoveId] = useState<number | null>(null)

    useEffect(() => {
        setLoading(true)
        getVehicleMembers(vehicle.id)
            .then(setMembers)
            .catch(err => setLoadError(err?.message || "Mitglieder konnten nicht geladen werden"))
            .finally(() => setLoading(false))
    }, [vehicle.id])

    const handleRemove = (profileId: number) => {
        setRemoveError(null)
        removeVehicleMember(vehicle.id, profileId)
            .then(() => setMembers(prev => prev.filter(m => m.profileId !== profileId)))
            .catch(err => setRemoveError(err?.message || "Mitglied konnte nicht entfernt werden"))
    }

    const confirmRemove = () => {
        if (confirmRemoveId === null) return
        handleRemove(confirmRemoveId)
        setConfirmRemoveId(null)
    }

    // Eigene Rolle aus der Mitgliederliste ableiten
    // (vehicle.myRole ist bereits bekannt, aber zur Sicherheit aus der Liste lesen)
    const myRole = vehicle.myRole

    const canRemove = (targetRole: string) => {
        if (myRole === "OWNER") return targetRole !== "OWNER"
        if (myRole === "CO_OWNER") return targetRole === "DRIVER"
        return false
    }

    const roleLabel = (role: string) => {
        switch (role) {
            case "OWNER":    return "Eigentümer"
            case "CO_OWNER": return "Co-Eigentümer"
            case "DRIVER":   return "Fahrer"
            default:         return role
        }
    }

    if (typeof document === "undefined") return null

    return createPortal(
        <div className="modal-overlay" onClick={onClose}>
            <div
                className="modal"
                onClick={(event) => event.stopPropagation()}
                style={{ width: "min(640px, 90vw)", padding: "24px", borderRadius: "24px" }}
            >
                <h3>Mitglieder – {vehicle.model} ({vehicle.licensePlate})</h3>

                {removeError && (
                    <p className="error-text" style={{ marginBottom: 12 }}>{removeError}</p>
                )}

                {loading && <p>Laden...</p>}
                {loadError && <p className="error-text">Fehler: {loadError}</p>}

                {!loading && !loadError && (
                    <table>
                        <thead>
                            <tr>
                                <th>Profil</th>
                                <th>Account</th>
                                <th>E-Mail</th>
                                <th>Rolle</th>
                                <th>Aktionen</th>
                            </tr>
                        </thead>
                        <tbody>
                            {members.map(member => (
                                <tr key={member.profileId}>
                                    <td>{member.profileName}</td>
                                    <td>{member.accountName}</td>
                                    <td>{member.accountEmail}</td>
                                    <td>{roleLabel(member.vehicleRole)}</td>
                                    <td>
                                        {canRemove(member.vehicleRole) && (
                                            <Button
                                                label="Entfernen"
                                                stopPropagation
                                                onClick={() => setConfirmRemoveId(member.profileId)}
                                            />
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}

                <div style={{ marginTop: 16 }}>
                    <Button label="Schließen" onClick={onClose} />
                </div>

                <ConfirmationDialog
                    open={confirmRemoveId !== null}
                    title="Mitglied entfernen"
                    message="Möchtest du dieses Mitglied wirklich vom Fahrzeug entfernen?"
                    confirmLabel="Entfernen"
                    cancelLabel="Abbrechen"
                    onConfirm={confirmRemove}
                    onCancel={() => setConfirmRemoveId(null)}
                />
            </div>
        </div>,
        document.body
    )
}