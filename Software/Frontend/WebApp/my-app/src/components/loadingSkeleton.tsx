// components/LoadingSkeleton.tsx
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

// Spinner für Button-Aktionen
export function ButtonSpinner() {
    return (
        <span
            style={{
                display: "inline-block",
                width: "14px",
                height: "14px",
                border: "2px solid rgba(255,255,255,0.4)",
                borderTopColor: "#fff",
                borderRadius: "50%",
                animation: "spin 0.6s linear infinite",
                verticalAlign: "middle",
                marginRight: "6px",
            }}
        />
    );
}

// Zentrierter Seiten-Spinner (für Tabellen/Seiten die keinen Skeleton haben)
export function PageSpinner() {
    return (
        <div style={{ display: "flex", justifyContent: "center", padding: "48px 0" }}>
            <span className="spinner" />
        </div>
    );
}

// für Tabellen
export function TableSkeleton({ rows = 5, cols = 4, title }: { rows?: number; cols?: number; title?: string }) {
    return (
        <div>
            {title && <h2>{title}</h2>}
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
                <tr>
                    {Array(cols).fill(0).map((_, i) => (
                        <th key={i} style={{ padding: "8px" }}>
                            <Skeleton height={14} />
                        </th>
                    ))}
                </tr>
            </thead>
            <tbody>
                {Array(rows).fill(0).map((_, i) => (
                    <tr key={i}>
                        {Array(cols).fill(0).map((_, j) => (
                            <td key={j} style={{ padding: "8px" }}>
                                <Skeleton height={14} />
                            </td>
                        ))}
                    </tr>
                ))}
            </tbody>
        </table>
        </div>
    );
}

// für Text/Paragraphen z.B Dashboard
export function TextSkeleton({ lines = 3 }: { lines?: number }) {
    return (
        <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
            {Array(lines).fill(0).map((_, i) => (
                <Skeleton key={i} height={14} width={i === lines - 1 ? "60%" : "100%"} />
            ))}
        </div>
    );
}

// für Karten z.B Profile, Vehicles
export function CardSkeleton({ count = 3 }: { count?: number }) {
    return (
        <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
            {Array(count).fill(0).map((_, i) => (
                <div key={i} style={{ padding: "16px", border: "1px solid #eee", borderRadius: "8px" }}>
                    <Skeleton height={20} width="40%" style={{ marginBottom: "8px" }} />
                    <Skeleton height={14} count={2} />
                </div>
            ))}
        </div>
    );
}

// für einzelne Werte z.B Dashboard Statistiken
export function StatSkeleton({ count = 4 }: { count?: number }) {
    return (
        <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
            {Array(count).fill(0).map((_, i) => (
                <div key={i} className="stat-card">
                    <Skeleton height={14} width="60%" style={{ marginBottom: "8px" }} />
                    <Skeleton height={32} width="40%" />
                </div>
            ))}
        </div>
    );
}

export function DashboardSkeleton() {
    return (
        <div>
            <Skeleton height={28} width="200px" style={{ marginBottom: "1.25rem" }} />

            <div className="dashboard-stat-grid" style={{ marginBottom: "1.5rem" }}>
                {Array(4).fill(0).map((_, i) => (
                    <div key={i} className="stat-card">
                        <Skeleton height={14} width="60%" style={{ marginBottom: "8px" }} />
                        <Skeleton height={32} width="40%" />
                    </div>
                ))}
            </div>

            <div className="dashboard-main-grid" style={{ marginBottom: "1.5rem" }}>
                <div className="dashboard-card">
                    <Skeleton height={14} width="100px" style={{ marginBottom: "12px" }} />
                    <Skeleton height={200} />
                </div>
                <div className="dashboard-card">
                    <Skeleton height={14} width="100px" style={{ marginBottom: "12px" }} />
                    <Skeleton height={20} width="60%" style={{ marginBottom: "4px" }} />
                    <Skeleton height={28} width="40%" style={{ marginBottom: "8px" }} />
                    <Skeleton height={150} />
                </div>
            </div>

            <div className="dashboard-trips-card">
                <Skeleton height={14} width="120px" style={{ marginBottom: "8px" }} />
                {Array(5).fill(0).map((_, i) => (
                    <div key={i} style={{ padding: "8px 0", borderBottom: "0.5px solid var(--color-border-tertiary)" }}>
                        <Skeleton height={14} />
                    </div>
                ))}
            </div>
        </div>
    );
}