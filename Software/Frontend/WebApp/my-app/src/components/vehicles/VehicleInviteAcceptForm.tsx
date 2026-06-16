import { useState } from "react"
import { Button } from "../button"
import { acceptVehicleInvite } from "../../services/vehicleService"

interface Props {
    onClose: () => void
    onSuccess: () => void
}

export function VehicleInviteAcceptForm({ onClose, onSuccess }: Props) {
    const [code, setCode] = useState("")
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const handleAccept = async () => {
        if (!code.trim()) return
        setLoading(true)
        setError(null)
        try {
            await acceptVehicleInvite(code)
            onSuccess()
        } catch (e: any) {
            setError(e.message)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="modal">
            <h3>Fahrzeug-Einladung annehmen</h3>

            {error && <p style={{ color: "red" }}>{error}</p>}

            <input
                placeholder="Einladungscode"
                value={code}
                onChange={e => setCode(e.target.value)}
                onKeyDown={e => e.key === "Enter" && handleAccept()}
            />

            <Button label={loading ? "..." : "Beitreten"} onClick={handleAccept} />
            <Button label="Schließen" onClick={onClose} />
        </div>
    )
}