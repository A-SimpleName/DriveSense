import StatCard from "../components/statCard";
import { Button } from "../components/button";
import { Link, useNavigate } from "react-router-dom";
import MapView from "../components/MapView";
import { getLatestTrip, getTotalKm, getAllTrips, getTripById, getTotalDuration } from "../services/tripService";
import { useEffect, useState } from "react";
import type { Tripdetailed, TripSummaryDto } from "../model/trip";
import { DashboardSkeleton } from "../components/loadingSkeleton";
import { useAuth } from "../context/authContext";
import "../styles/dashboard.css";

function Dashboard() {
    const navigate = useNavigate();
    const { profile } = useAuth();
    const [lastTripDetailed, setLastTripDetailed] = useState<Tripdetailed | null>(null);
    const [totalKm, setTotalKm] = useState<string>("0 km");
    const [tripAmount, setTripAmount] = useState<number>(0);
    const [recentTrips, setRecentTrips] = useState<TripSummaryDto[]>([]);
    const [weekTrips, setWeekTrips] = useState<TripSummaryDto[]>([]);
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
                setTripAmount(all.length);
                setRecentTrips(all.slice(0, 5));

                const sevenDaysAgo = new Date();
                sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
                sevenDaysAgo.setHours(0, 0, 0, 0);
                setWeekTrips(all.filter(t => new Date(t.startTime) >= sevenDaysAgo));

                if (latest) return getTripById(latest.id);
                return null;
            })
            .then(detailed => {
                if (detailed) setLastTripDetailed(detailed);
            })
            .catch(err => setError(err.message))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <DashboardSkeleton />;
    if (error) return <p>Fehler: {error}</p>;

    const greeting = () => {
        const h = new Date().getHours();
        if (h < 12) return "Guten Morgen";
        if (h < 18) return "Guten Tag";
        return "Guten Abend";
    };

    const lastTrip = lastTripDetailed?.tripSummary;
    const route = lastTripDetailed?.trackingpoints?.map(p => ({ lat: p.lat, lng: p.lng })) ?? [];

    const weekDayShort = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"];
    // Chronologische Liste der letzten 7 Kalendertage (älteste zuerst), damit
    // die Achse immer "heute und die letzten 6 Tage" zeigt statt einer fixen
    // So-Sa-Reihenfolge, die bei älteren/lückenhaften Daten irreführend wäre.
    const last7Days = Array.from({ length: 7 }, (_, i) => {
        const d = new Date();
        d.setDate(d.getDate() - (6 - i));
        d.setHours(0, 0, 0, 0);
        return d;
    });
    const kmPerDay = last7Days.map(day => {
        const km = weekTrips
            .filter(t => {
                const tripDay = new Date(t.startTime);
                tripDay.setHours(0, 0, 0, 0);
                return tripDay.getTime() === day.getTime();
            })
            .reduce((sum, t) => sum + (parseFloat(String(t.distance)) || 0), 0);
        return { date: day, label: weekDayShort[day.getDay()], km };
    });
    const maxKm = Math.max(...kmPerDay.map(d => d.km), 1);

    return (
        <div>
            <h2 className="dashboard-greeting">
                {greeting()}{profile?.name ? `, ${profile.name}` : ""}
            </h2>

            <div className="dashboard-stat-grid">
                <StatCard title="Gesamtstrecke" value={totalKm} />
                <StatCard title="Fahrten" value={`${tripAmount}`} />
                <StatCard title="Fahrzeit gesamt" value={`${Math.floor(totalDuration / 60)}h ${totalDuration % 60}min`} />
                {lastTrip && <StatCard title="Letzte Fahrt" value={`${lastTrip.distance} km`} />}
            </div>

            {tripAmount === 0 ? (
                <div className="dashboard-empty">
                    <span className="dashboard-empty-icon" aria-hidden="true">🚗</span>
                    <p className="dashboard-empty-title">Noch keine Fahrten aufgezeichnet</p>
                    <p className="dashboard-empty-subtitle">
                        lade dir die App herunter und starte deine erste Fahrt, um deine gefahrenen Kilometer hier im Überblick zu sehen.
                    </p>
                </div>
            ) : (
                <div className="dashboard-main-grid">
                    <div className="dashboard-card">
                        <p className="dashboard-card-title">Letzte 7 Tage (km)</p>
                        <div className="dashboard-bar-chart">
                            {kmPerDay.map((day, i) => {
                                const height = Math.max(Math.round((day.km / maxKm) * 360), day.km > 0 ? 4 : 0);
                                return (
                                    <div key={i} className="dashboard-bar-col">
                                        <div className="dashboard-bar" style={{ height: `${height}px` }} />
                                        <span className="dashboard-bar-label">{day.label}</span>
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
            )}

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
                    <Button label="Gruppen" className="dashboard-action-btn" />
                </Link>
                <Link to="/vehicles" style={{ flex: 1 }}>
                    <Button label="Fahrzeuge" className="dashboard-action-btn" />
                </Link>
            </div>
        </div>
    );
}

export default Dashboard;