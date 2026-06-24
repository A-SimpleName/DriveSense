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
            const dropdownWidth = 180;
            const margin = 8;

            // Rechtsbündig unter dem Trigger ausrichten, aber innerhalb des
            // Viewports halten – auf schmalen Bildschirmen (z.B. bei
            // horizontal scrollenden Tabellen) kann der Trigger sehr nah am
            // linken Rand liegen, wo rect.right - 180 sonst negativ würde.
            const left = Math.min(
                Math.max(rect.right - dropdownWidth, margin),
                window.innerWidth - dropdownWidth - margin
            );

            setPosition({ top: rect.bottom + 4, left });
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