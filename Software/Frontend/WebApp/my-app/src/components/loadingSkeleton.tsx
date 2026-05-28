// components/LoadingSkeleton.tsx
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

// für Tabellen
export function TableSkeleton({ rows = 5, cols = 4 }: { rows?: number; cols?: number }) {
    return (
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
        <div style={{ display: "grid", gridTemplateColumns: `repeat(${count}, 1fr)`, gap: "16px" }}>
            {Array(count).fill(0).map((_, i) => (
                <div key={i} style={{ padding: "16px", border: "1px solid #eee", borderRadius: "8px" }}>
                    <Skeleton height={14} width="60%" style={{ marginBottom: "8px" }} />
                    <Skeleton height={32} width="40%" />
                </div>
            ))}
        </div>
    );
}