import { useState } from "react"
import "../styles/addForms.css"
import { getFieldErrors } from "../errorHandling/errorHandling"

export type FieldDef =
    | { type: "text" | "number"; key: string; label: string; placeholder?: string; defaultValue?: string | number }
    | { type: "select"; key: string; label: string; options: { label: string; value: string }[]; defaultValue?: string }

interface Props {
    title: string
    fields: FieldDef[]
    onClose: () => void
    onSubmit: (values: Record<string, string | number>) => Promise<void>
    submitLabel?: string
}

export function AddForm({ title, fields, onClose, onSubmit, submitLabel = "Hinzufügen" }: Props) {
    const [values, setValues] = useState<Record<string, string | number>>(
        Object.fromEntries(fields.map(f => [f.key, f.defaultValue ?? (f.type === "number" ? 0 : "")]))
    )
    const [globalError, setGlobalError] = useState<string | null>(null)
    const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
    const [saving, setSaving] = useState(false)

    function set(key: string, value: string | number) {
        setValues(prev => ({ ...prev, [key]: value }))
        // Inline-Fehler beim Tippen wegräumen
        if (fieldErrors[key]) {
            setFieldErrors(prev => { const next = { ...prev }; delete next[key]; return next })
        }
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault()

        const empty = fields.find(f => f.type !== "number" && !String(values[f.key]).trim())
        if (empty) {
            setFieldErrors({ [empty.key]: `Bitte "${empty.label}" ausfüllen` })
            return
        }

        setSaving(true)
        setGlobalError(null)
        setFieldErrors({})

        try {
            await onSubmit(values)
            onClose()
        } catch (err: any) {
            // Feldfehler vom Backend → inline pro Feld anzeigen
            const backendFieldErrors = getFieldErrors(err)
            if (backendFieldErrors && Object.keys(backendFieldErrors).length > 0) {
                setFieldErrors(backendFieldErrors)
            } else {
                // Allgemeiner Fehler → als Banner
                setGlobalError(err?.message || "Fehler beim Speichern")
            }
        } finally {
            setSaving(false)
        }
    }

    return (
        <div className="addForm-overlay">
            <div className="addForm">
                <div className="addForm-header">
                    <h2>{title}</h2>
                    <button type="button" className="addForm-close" onClick={onClose} aria-label="Schließen">✕</button>
                </div>

                {globalError && <p className="addForm-error">{globalError}</p>}

                <form onSubmit={handleSubmit}>
                    <div className="addForm-body">
                        {fields.map(field => (
                            <div
                                key={field.key}
                                className={`addForm-field ${fieldErrors[field.key] ? "addForm-field--error" : ""}`}
                            >
                                <label htmlFor={field.key}>{field.label}</label>

                                {field.type === "select" ? (
                                    <select
                                        id={field.key}
                                        value={String(values[field.key])}
                                        onChange={e => set(field.key, e.target.value)}
                                    >
                                        {field.options.map(o => (
                                            <option key={o.value} value={o.value}>{o.label}</option>
                                        ))}
                                    </select>
                                ) : (
                                    <input
                                        id={field.key}
                                        type={field.type}
                                        value={values[field.key]}
                                        placeholder={"placeholder" in field ? field.placeholder : undefined}
                                        onChange={e => set(field.key, field.type === "number" ? Number(e.target.value) : e.target.value)}
                                    />
                                )}

                                {/* Inline-Fehler pro Feld */}
                                {fieldErrors[field.key] && (
                                    <span className="addForm-field-error">{fieldErrors[field.key]}</span>
                                )}
                            </div>
                        ))}
                    </div>

                    <div className="addForm-footer">
                        <button type="button" className="addForm-cancel" onClick={onClose}>Abbrechen</button>
                        <button type="submit" className="addForm-submit" disabled={saving}>
                            {saving ? "Wird gespeichert…" : submitLabel}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    )
}