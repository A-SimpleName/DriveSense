import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link, useNavigate } from "react-router-dom";
import MapView from "../components/MapView";
import { getLatestTrip, getTotalKm, getAllTrips, getTripById, getTotalDuration } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed, TripSummaryDto } from "../model/trip";
import { StatSkeleton } from "../components/loadingSkeleton";
import { useAuth } from "../context/authContext";
import "../styles/dashboard.css";

function Dashboard() {
    const navigate = useNavigate();
    const { profile } = useAuth();
    const [lastTripDetailed, setLastTripDetailed] = useState<Tripdetailed | null>(null);
    const [totalKm, setTotalKm] = useState<string>("0 km");
    const [recentTrips, setRecentTrips] = useState<TripSummaryDto[]>([]);
    const [totalDuration, setTotalDuration] = useState<number>(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        Promise.all([
            getLatestTrip(),
            getTotalKm(),
            getAllTrips(),
            getTotalDuration(),
        ])
            .then(([latest, km, all, duration]) => {
                setTotalKm(`${km} km`);
                setTotalDuration(duration);
                setRecentTrips(all.slice(0, 5));
                if (latest) return getTripById(latest.id);
                return null;
            })
            .then(detailed => {
                if (detailed) setLastTripDetailed(detailed);
            })
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <StatSkeleton count={4} />;
    if (error) return <p>Fehler: {error}</p>;

    const greeting = () => {
        const h = new Date().getHours();
        if (h < 12) return "Guten Morgen";
        if (h < 18) return "Guten Tag";
        return "Guten Abend";
    };

    const lastTrip = lastTripDetailed?.tripSummary;
    const route = lastTripDetailed?.trackingpoints?.map(p => ({ lat: p.lat, lng: p.lng })) ?? [];

    const weekDays = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"];
    const kmPerDay = recentTrips.reduce<Record<number, number>>((acc, t) => {
        const day = new Date(t.startTime).getDay();
        acc[day] = (acc[day] ?? 0) + (parseFloat(String(t.distance)) || 0);
        return acc;
    }, {});
    const maxKm = Math.max(...Object.values(kmPerDay), 1);

    return (
        <div>
            <h2 className="dashboard-greeting">
                {greeting()}{profile?.name ? `, ${profile.name}` : ""}
            </h2>

            <div className="dashboard-stat-grid">
                <StatCard title="Gesamtstrecke" value={totalKm} />
                <StatCard title="Fahrten" value={`${recentTrips.length}`} />
                <StatCard title="Fahrzeit gesamt" value={`${Math.floor(totalDuration / 60)}h ${totalDuration % 60}min`} />
                {lastTrip && <StatCard title="Letzte Fahrt" value={`${lastTrip.distance} km`} />}
            </div>

            <div className="dashboard-main-grid">
                <div className="dashboard-card">
                    <p className="dashboard-card-title">Woche (km)</p>
                    <div className="dashboard-bar-chart">
                        {weekDays.map((label, i) => {
                            const km = kmPerDay[i] ?? 0;
                            const height = Math.max(Math.round((km / maxKm) * 360), km > 0 ? 4 : 0);
                            return (
                                <div key={i} className="dashboard-bar-col">
                                    <div className="dashboard-bar" style={{ height: `${height}px` }} />
                                    <span className="dashboard-bar-label">{label}</span>
                                </div>
                            );
                        })}
                    </div>
                </div>

                {lastTrip && (
                    <div className="dashboard-card">
                        <p className="dashboard-card-title">Letzte Fahrt</p>
                        <p className="dashboard-card-subtitle">{lastTrip.startPoint} → {lastTrip.endPoint}</p>
                        <p className="dashboard-card-value">{lastTrip.distance} km</p>
                        {route.length > 0 && <MapView route={route} />}
                    </div>
                )}
            </div>

            {recentTrips.length > 0 && (
                <div className="dashboard-trips-card">
                    <p className="dashboard-card-title">Letzte Fahrten</p>
                    {recentTrips.map(t => (
                        <div key={t.id} className="dashboard-trip-row" onClick={() => navigate(`/trips/${t.id}`)}>
                            <span className="dashboard-trip-route">{t.startPoint} → {t.endPoint}</span>
                            <span className="dashboard-trip-distance">{t.distance} km</span>
                            <span className="dashboard-trip-condition">{t.roadSurfaceConditions}</span>
                            <span className="dashboard-trip-date">{new Date(t.startTime).toLocaleDateString()}</span>
                        </div>
                    ))}
                </div>
            )}

            <div className="dashboard-actions">
                <Link to="/trips" style={{ flex: 1 }}>
                    <Button label="Alle Fahrten" className="dashboard-action-btn" />
                </Link>
                <Link to="/groups" style={{ flex: 1 }}>
                    <Button label="Gruppen ansehen" className="dashboard-action-btn" />
                </Link>
                <Link to="/vehicles" style={{ flex: 1 }}>
                    <Button label="Fahrzeuge" className="dashboard-action-btn" />
                </Link>
            </div>
        </div>
    );
}

export default Dashboard;