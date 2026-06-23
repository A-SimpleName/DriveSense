import { useEffect, useState } from "react";

const DISMISS_KEY = "mobileWarningDismissed";
const BREAKPOINT = 860;

// Zeigt einen wegklickbaren Hinweis, dass die Web-App für größere Displays
// gedacht ist und auf dem Smartphone die native App genutzt werden sollte.
// Erkennung per Bildschirmbreite (robuster als User-Agent-Sniffing, reagiert
// außerdem live auf Drehung/Resize).
export default function MobileWarningBanner() {
    const [isNarrow, setIsNarrow] = useState(() => window.innerWidth < BREAKPOINT);
    const [dismissed, setDismissed] = useState(() => sessionStorage.getItem(DISMISS_KEY) === "true");

    useEffect(() => {
        const onResize = () => setIsNarrow(window.innerWidth < BREAKPOINT);
        window.addEventListener("resize", onResize);
        return () => window.removeEventListener("resize", onResize);
    }, []);

    if (!isNarrow || dismissed) return null;

    const handleDismiss = () => {
        sessionStorage.setItem(DISMISS_KEY, "true");
        setDismissed(true);
    };

    return (
        <div className="mobile-warning-banner">
            <span className="mobile-warning-text">
                Diese Website ist für größere Bildschirme optimiert. Für die beste Erfahrung auf dem Smartphone nutze bitte die DriveSense-App.
            </span>
            <button
                className="mobile-warning-close"
                onClick={handleDismiss}
                aria-label="Hinweis schließen"
                type="button"
            >
                ×
            </button>
        </div>
    );
}
