import { useState } from "react"
import { Button } from "./button"

interface Props {
    title: string
    placeholder?: string
    maxLength?: number

    onVerify: (code: string) => Promise<void>
    onSuccess: () => void
    onClose: () => void
}

export function InviteCodeForm({
    title,
    placeholder = "Code eingeben",
    maxLength,
    onVerify,
    onSuccess,
    onClose
}: Props) {
    const [code, setCode] = useState("")
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const handleSubmit = async () => {
        if (!code.trim()) return

        setLoading(true)
        setError(null)

        try {
            await onVerify(code.trim())
            onSuccess()
        } catch (e: any) {
            setError(e?.message || "Ungültiger Code")
        } finally {
            setLoading(false)
        }
    }

    const handleOverlayClick = () => {
        if (!loading) onClose()
    }

    return (
        <div
            onClick={handleOverlayClick}
            style={{
                position: "fixed",
                inset: 0,
                background: "rgba(0,0,0,0.5)",
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
                zIndex: 1000
            }}
        >
            <div
                onClick={e => e.stopPropagation()}
                style={{
                    position: "relative",
                    width: "100%",
                    maxWidth: 420,
                    background: "#fff",
                    borderRadius: 10,
                    padding: 20,
                    display: "flex",
                    flexDirection: "column",
                    gap: 12
                }}
            >
                {/* X Button */}
                <button
                    onClick={onClose}
                    style={{
                        position: "absolute",
                        top: 10,
                        right: 10,
                        border: "none",
                        background: "transparent",
                        fontSize: 18,
                        cursor: "pointer",
                        color: "black"
                    }}
                >
                    ✕
                </button>

                <h3>{title}</h3>

                {error && <p style={{ color: "red" }}>{error}</p>}

                <input
                    value={code}
                    placeholder={placeholder}
                    maxLength={maxLength}
                    onChange={e => setCode(e.target.value)}
                    onKeyDown={e => e.key === "Enter" && handleSubmit()}
                    style={{
                        padding: "10px",
                        fontSize: "1.1rem",
                        textAlign: "center",
                        letterSpacing: "2px"
                    }}
                />

                <Button
                    label={loading ? "..." : "Beitreten"}
                    onClick={handleSubmit}
                />
            </div>
        </div>
    )
}