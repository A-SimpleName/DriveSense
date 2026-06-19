import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import "../styles/actionMenu.css";

export interface ActionMenuItem {
    label: string;
    onClick: () => void;
    // z.B. für "Löschen" oder "Verlassen", optisch in Rot abgehoben
    danger?: boolean;
}

interface Props {
    items: ActionMenuItem[];
}

// Kebab-Dropdown (⋮) für Tabellenzeilen mit mehreren möglichen Aktionen,
// statt viele Buttons nebeneinander zu zeigen. Rendert über createPortal an
// document.body, da Tabellen-Wrapper hier overflow:hidden nutzen und ein
// normal positioniertes Dropdown sonst am Rand abgeschnitten würde.
export function ActionMenu({ items }: Props) {
    const [open, setOpen] = useState(false);
    const [position, setPosition] = useState({ top: 0, left: 0 });
    const triggerRef = useRef<HTMLButtonElement>(null);
    const dropdownRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            const target = event.target as Node;
            if (
                triggerRef.current && !triggerRef.current.contains(target) &&
                dropdownRef.current && !dropdownRef.current.contains(target)
            ) {
                setOpen(false);
            }
        };

        if (open) {
            document.addEventListener("click", handleClickOutside);
        }

        return () => {
            document.removeEventListener("click", handleClickOutside);
        };
    }, [open]);

    const handleTriggerClick = (e: React.MouseEvent) => {
        e.stopPropagation();
        if (!open && triggerRef.current) {
            const rect = triggerRef.current.getBoundingClientRect();
            // Rechtsbündig unter dem Trigger ausrichten, Breite des
            // Dropdowns (180px, siehe CSS) wird dafür abgezogen
            setPosition({ top: rect.bottom + 4, left: rect.right - 180 });
        }
        setOpen(prev => !prev);
    };

    if (items.length === 0) return null;

    return (
        <>
            <button
                ref={triggerRef}
                type="button"
                className="action-menu-trigger"
                onClick={handleTriggerClick}
                aria-label="Aktionen anzeigen"
                aria-haspopup="true"
                aria-expanded={open}
            >
                ⋮
            </button>

            {open && typeof document !== "undefined" && createPortal(
                <div
                    ref={dropdownRef}
                    className="action-menu-dropdown"
                    style={{ position: "fixed", top: position.top, left: position.left }}
                >
                    {items.map((item, i) => (
                        <button
                            key={i}
                            type="button"
                            className={`action-menu-item ${item.danger ? "action-menu-item--danger" : ""}`}
                            onClick={(e) => {
                                e.stopPropagation();
                                setOpen(false);
                                item.onClick();
                            }}
                        >
                            {item.label}
                        </button>
                    ))}
                </div>,
                document.body
            )}
        </>
    );
}
