type Props = {
  label: string;
  value: string;
};

// Für reine, nicht-interaktive Anzeige eines Werts (z.B. Account-Stammdaten).
// Im Gegensatz zu StatCard kein Hover-Lift und kein cursor:pointer,
// da hier nichts klickbar ist.
export default function InfoRow({ label, value }: Props) {
  return (
    <div className="info-row">
      <span className="info-row-label">{label}</span>
      <span className="info-row-value">{value}</span>
    </div>
  );
}
