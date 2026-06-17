type Props = {
  title: string;
  value: string;
};

export default function StatCard({ title, value }: Props) {
  return (
    <div className="stat-card">
      <h3 className="stat-card-label">{title}</h3>
      <p className="stat-card-value">{value}</p>
    </div>
  );
}
