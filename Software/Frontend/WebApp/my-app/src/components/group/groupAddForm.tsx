import { AddForm } from "../addForm"
import { createGroup } from "../../services/groupService"
import type { UserGroup } from "../../model/usergroup"
 
interface GroupProps {
    onClose: () => void
    onCreated: (group: UserGroup) => void
}
 
export function GroupAddForm({ onClose, onCreated }: GroupProps) {
    return (
        <AddForm
            title="Gruppe erstellen"
            fields={[
                { type: "text", key: "name", label: "Gruppenname" }
            ]}
            submitLabel="Erstellen"
            onClose={onClose}
            onSubmit={async ({ name }) => {
                const group = await createGroup(String(name).trim())
                onCreated(group)
            }}
        />
    )
}