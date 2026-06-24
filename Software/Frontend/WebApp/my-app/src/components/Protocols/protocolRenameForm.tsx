import { AddForm } from "../addForm";
import { updateProtocol } from "../../services/protocolService";
import type { Protocol } from "../../model/protocol";

interface ProtocolRenameFormProps {
    protocol: Protocol;
    onClose: () => void;
    onSuccess: () => void;
}

export function ProtocolRenameForm({
    protocol,
    onClose,
    onSuccess,
}: ProtocolRenameFormProps) {
    return (
        <AddForm
            title="Protokoll umbenennen"
            submitLabel="Speichern"
            fields={[
                {
                    type: "text",
                    key: "name",
                    label: "Name",
                    defaultValue: protocol.name,
                },
            ]}
            onClose={onClose}
            onSubmit={async ({ name }) => {
                await updateProtocol(protocol.id, {
                    created_by_profileId: protocol.created_by_profileId,
                    usergroupId: protocol.usergroupId,
                    created_at: protocol.created_at,
                    name: String(name).trim(),
                });
                onSuccess();
            }}
        />
    );
}
