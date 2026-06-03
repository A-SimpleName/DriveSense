import { AddForm } from "../addForm"
import { createProtocol } from "../../services/protocolService"
 
interface ProtocolProps {
    onClose: () => void
    onSuccess: () => void
    usergroupId: number | null
}
 
export function ProtocolAddForm({ onClose, onSuccess, usergroupId }: ProtocolProps) {
    return (
        <AddForm
            title="Protokoll hinzufügen"
            fields={[
                { type: "text", key: "name", label: "Name" }
            ]}
            onClose={onClose}
            onSubmit={async ({ name }) => {
                await createProtocol({ name: String(name), usergroupId })
                onSuccess()
            }}
        />
    )
}