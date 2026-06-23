import { createPortal } from "react-dom";
import { Button } from "./button";
import { Check, X } from "lucide-react";

type ConfirmationDialogProps = {
  open: boolean;
  title?: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  confirmLoading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
};

export function ConfirmationDialog({
  open,
  title = "Bestätigung",
  message,
  confirmLabel = "Löschen",
  cancelLabel = "Abbrechen",
  confirmLoading = false,
  onConfirm,
  onCancel,
}: ConfirmationDialogProps) {
  if (!open || typeof document === "undefined") return null;

  return createPortal(
    <div className="modal-overlay" onClick={onCancel}>
      <div
        className="modal"
        onClick={(event) => event.stopPropagation()}
        style={{
          width: "min(480px, 90vw)",
          padding: "24px",
          borderRadius: "24px",
          background: "var(--surface)",
        }}
      >
        <div style={{ marginBottom: "20px" }}>
          <h2 style={{ margin: 0, fontSize: "1.25rem", color: "var(--text)" }}>
            {title}
          </h2>
          <p style={{ marginTop: "14px", color: "var(--text-secondary)", lineHeight: 1.65 }}>
            {message}
          </p>
        </div>

        <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", marginTop: "24px" }}>
          <Button className="secondary small" label={cancelLabel} onClick={onCancel} disabled={confirmLoading} icon={<X size={16} />} />
          <Button label={confirmLoading ? `${confirmLabel}...` : confirmLabel} loading={confirmLoading} onClick={onConfirm} icon={<Check size={16} />} />
        </div>
      </div>
    </div>,
    document.body
  );
}
