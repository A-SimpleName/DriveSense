import { useEffect, useState } from "react"
import { createPortal } from "react-dom"
import { getVehicleMembers, removeVehicleMember, updateVehicleMemberRole, deleteVehicle } from "../../services/vehicleService"
import { Button } from "../button"
import { ActionMenu, type ActionMenuItem } from "../ActionMenu"
import { ConfirmationDialog } from "../ConfirmationDialog"
import { useAuth } from "../../context/authContext"
import type { Vehicle, VehicleMember } from "../../model/vehicle"

interface Props {
    vehicle: Vehicle
    onClose: () => void
    // Wird zusätzlich zu onClose gefeuert, wenn man das Fahrzeug über
    // "Verlassen" selbst verlässt, damit die Eltern-Tabelle das Fahrzeug
    // sofort aus ihrer Liste entfernen kann
    onLeft?: () => void
    // Wird von außen erhöht (z.B. nach einer neuen Einladung), um die
    // Mitgliederliste ohne Schließen/Wiederöffnen neu zu laden
    reloadToken?: number
}

export function VehicleMembers({ vehicle, onClose, onLeft, reloadToken = 0 }: Props) {
    const { profile } = useAuth();
    const [members, setMembers] = useState<VehicleMember[]>([])
    const [loading, setLoading] = useState(false)
    const [loadError, setLoadError] = useState<string | null>(null)
    const [removeError, setRemoveError] = useState<string | null>(null)
    const [roleError, setRoleError] = useState<string | null>(null)
    const [confirmRemove, setConfirmRemove] = useState<{ profileId: number; message: string; leavingSelf: boolean } | null>(null)

    useEffect(() => {
        setLoading(true)
        getVehicleMembers(vehicle.id)
            .then(setMembers)
            .catch(err => setLoadError(err?.message || "Mitglieder konnten nicht geladen werden"))
            .finally(() => setLoading(false))
    }, [vehicle.id, reloadToken])

    const handleRemove = (profileId: number) => {
        setRemoveError(null)
        removeVehicleMember(vehicle.id, profileId)
            .then(() => setMembers(prev => prev.filter(m => m.profileId !== profileId)))
            .catch(err => setRemoveError(err?.message || "Mitglied konnte nicht entfernt werden"))
    }

    const requestRemove = (profileId: number, message: string, leavingSelf: boolean) => {
        setConfirmRemove({ profileId, message, leavingSelf })
    }

    const confirmRemoveAction = () => {
        if (!confirmRemove) return
        const { leavingSelf } = confirmRemove
        setConfirmRemove(null)
        if (leavingSelf) {
            // Verlassen läuft über denselben Endpunkt wie das Löschen eines
            // Fahrzeugs: das Backend unterscheidet selbst zwischen Soft-Delete
            // (wenn man OWNER ist) und Verlassen (sonst). removeVehicleMember
            // wäre hier falsch, da Self-Removal darüber explizit gesperrt ist.
            deleteVehicle(vehicle.id)
                .then(() => {
                    onClose()
                    onLeft?.()
                })
                .catch(err => setRemoveError(err?.message || "Fahrzeug konnte nicht verlassen werden"))
        } else {
            handleRemove(confirmRemove.profileId)
        }
    }

    const handlePromote = (profileId: number, currentRole: "CO_OWNER" | "DRIVER") => {
        const newRole = currentRole === "DRIVER" ? "CO_OWNER" : "DRIVER"
        setRoleError(null)
        updateVehicleMemberRole(vehicle.id, profileId, newRole)
            .then(() =>
                setMembers(prev =>
                    prev.map(m => m.profileId === profileId ? { ...m, vehicleRole: newRole } : m)
                )
            )
            .catch(err => setRoleError(err?.message || "Rolle konnte nicht geändert werden"))
    }

    // Eigene Rolle aus der Mitgliederliste ableiten
    // (vehicle.myRole ist bereits bekannt, aber zur Sicherheit aus der Liste lesen)
    const myRole = vehicle.myRole

    const canRemove = (targetRole: string) => {
        if (myRole === "OWNER") return targetRole !== "OWNER"
        if (myRole === "CO_OWNER") return targetRole === "DRIVER"
        return false
    }

    // Nur der OWNER darf befördern/degradieren – zwischen Fahrer und
    // Co-Eigentümer hin und her. Der OWNER selbst kann nicht verändert werden.
    const canChangeRole = (targetRole: string) => {
        if (targetRole === "OWNER") return false
        return myRole === "OWNER"
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
                style={{ width: "min(880px, 90vw)", padding: "24px", borderRadius: "24px" }}
            >
                <h3>Mitglieder – {vehicle.model} ({vehicle.licensePlate})</h3>

                {removeError && (
                    <p className="error-text" style={{ marginBottom: 12 }}>{removeError}</p>
                )}
                {roleError && (
                    <p className="error-text" style={{ marginBottom: 12 }}>{roleError}</p>
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
                            {members.map(member => {
                                const isSelf = profile?.id === member.profileId;
                                const actions: ActionMenuItem[] = [
                                    ...(!isSelf && canChangeRole(member.vehicleRole) ? [{
                                        label: member.vehicleRole === "DRIVER" ? "Zu Co-Eigentümer" : "Zu Fahrer",
                                        onClick: () => handlePromote(member.profileId, member.vehicleRole as "CO_OWNER" | "DRIVER")
                                    }] : []),
                                    ...(!isSelf && canRemove(member.vehicleRole) ? [{
                                        label: "Entfernen",
                                        danger: true,
                                        onClick: () => requestRemove(
                                            member.profileId,
                                            `Mitglied ${member.profileName} wirklich vom Fahrzeug entfernen?`,
                                            false
                                        )
                                    }] : []),
                                    ...(isSelf && myRole !== "OWNER" ? [{
                                        label: "Verlassen",
                                        danger: true,
                                        onClick: () => requestRemove(
                                            member.profileId,
                                            "Möchtest du dieses Fahrzeug wirklich verlassen?",
                                            true
                                        )
                                    }] : [])
                                ];
                                return (
                                    <tr key={member.profileId}>
                                        <td>{member.profileName}</td>
                                        <td>{member.accountName}</td>
                                        <td>{member.accountEmail}</td>
                                        <td>{roleLabel(member.vehicleRole)}</td>
                                        <td>
                                            <ActionMenu items={actions} />
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                )}

                <div style={{ marginTop: 16 }}>
                    <Button label="Schließen" onClick={onClose} />
                </div>

                <ConfirmationDialog
                    open={confirmRemove !== null}
                    title={confirmRemove?.leavingSelf ? "Fahrzeug verlassen" : "Mitglied entfernen"}
                    message={confirmRemove?.message ?? "Soll die Aktion wirklich ausgeführt werden?"}
                    confirmLabel={confirmRemove?.leavingSelf ? "Verlassen" : "Entfernen"}
                    cancelLabel="Abbrechen"
                    onConfirm={confirmRemoveAction}
                    onCancel={() => setConfirmRemove(null)}
                />
            </div>
        </div>,
        document.body
    )
}