import type { ProtocolDetail } from "../../model/protocol";
import type { TripSummary } from "../../model/trip";
import "../../styles/protocol.css"

type ProtocolType = "FAHRSCHÜLER" | "PRIVAT" | "BERUFSFAHRER";

export default function ProtocolView({
    protocol,
    type,
    isGroup,
}: {
    protocol: ProtocolDetail;
    type: ProtocolType;
    isGroup: boolean;
}) {
    const trips = protocol.trips ?? [];
    const totalKm = trips.map(trip => trip.distance).reduce((a, b) => a + b, 0);
    const birthdate = protocol.created_by_account?.birthdate
        ? new Date(protocol.created_by_account.birthdate).toLocaleDateString()
        : "";

    const getColumns = () => {
        switch (type) {
            case "FAHRSCHÜLER":
                return [
                    ...(isGroup ? ["Fahrer"] : []),
                    "Datum",
                    "km",
                    "Von",
                    "Bis",
                    "KFZ",
                    "Tageszeit",
                    "Strecke",
                    "Zustand",
                ];

            case "PRIVAT":
                return [
                    ...(isGroup ? ["Fahrer"] : []),
                    "Datum",
                    "Start",
                    "Ziel",
                    "km-Start",
                    "km-Ende",
                    "Strecke",
                    "KFZ",
                ];

            case "BERUFSFAHRER":
                return [
                    ...(isGroup ? ["Fahrer"] : []),
                    "Datum",
                    "Start",
                    "Ziel",
                    "km",
                    "Tätigkeit",
                    "KFZ",
                ];
        }
    };

    const renderRow = (trip: TripSummary, i: number) => {
        return (
            <tr key={i}>
                {isGroup && (
                    <td className="left">
                        {trip.accountFname} {trip.accountLname}
                    </td>
                )}

                {type === "FAHRSCHÜLER" && (
                    <>
                        <td>
                            {new Date(trip.startTime).toLocaleDateString(
                                "de-AT"
                            )}
                        </td>
                        <td>{trip.distance}</td>
                        <td>{trip.startMileage}</td>
                        <td>{trip.endMileage}</td>
                        <td>{trip.licensePlate}</td>
                        <td>
                            {new Date(trip.endTime).toLocaleTimeString(
                                "de-AT",
                                {
                                    hour: "2-digit",
                                    minute: "2-digit",
                                }
                            )}
                        </td>
                        <td>
                            {trip.startPoint} → {trip.furthestPoint} → {trip.endPoint}
                        </td>
                        <td>{trip.roadSurfaceConditions}</td>
                    </>
                )}

                {type === "PRIVAT" && (
                    <>
                        <td>
                            {new Date(trip.startTime).toLocaleDateString(
                                "de-AT"
                            )}
                        </td>
                        <td className="left">{trip.startPoint}</td>
                        <td className="left">{trip.endPoint}</td>
                        <td>{trip.startMileage}</td>
                        <td>{trip.endMileage}</td>
                        <td>{trip.distance} km</td>
                        <td>{trip.licensePlate}</td>
                    </>
                )}

                {type === "BERUFSFAHRER" && (
                    <>
                        <td>
                            {new Date(trip.startTime).toLocaleDateString(
                                "de-AT"
                            )}
                        </td>
                        <td className="left">{trip.startPoint}</td>
                        <td className="left">{trip.endPoint}</td>
                        <td>{trip.distance} km</td>
                        <td>{trip.type}</td>
                        <td>{trip.licensePlate}</td>
                    </>
                )}
            </tr>
        );
    };

    const columns = getColumns();

    return (
        <div className="pdf-container">
            {/* HEADER */}
            <div className="header">
                <div className="left">
                    <span className="brand">DRIVESENSE</span>

                    <div className="proto-name">
                        {isGroup ? protocol.usergroup?.name : protocol.name}
                    </div>

                    <div className="proto-sub">
                        {isGroup ? "Gruppenprotokoll" : "Einzelprotokoll"} ·{" "}
                        {type.toUpperCase()}
                    </div>
                </div>

                {!isGroup && (
                    <div className="right">
                        <div className="proto-sub">
                            {protocol.created_by_account?.fname} {protocol.created_by_account?.lname}
                        </div>
                        <div className="user-info">
                            geb. {birthdate}
                        </div>
                    </div>
                )}
            </div>

            <div className="accent"></div>

            {/* SUMMARY */}
            <div className="summary">
                <div className="sum-cell">
                    <div className="sum-val">{totalKm} km</div>
                    <div className="sum-lbl">Gesamtstrecke</div>
                </div>
                <div className="sum-cell">
                    <div className="sum-val">{trips.length}</div>
                    <div className="sum-lbl">Fahrten</div>
                </div>
            </div>

            <div className="section-title">Fahrtenübersicht</div>

            {/* TABLE */}
            <table>
                <thead>
                    <tr>
                        {columns.map((c) => (
                            <th key={c}>{c}</th>
                        ))}
                    </tr>
                </thead>

                <tbody>
                    {trips.map((trip: TripSummary, i: number) =>
                        renderRow(trip, i)
                    )}
                </tbody>
            </table>

            {/* FOOTER */}
            <div className="footer">
                <div className="left">drivesense.app</div>
                <div className="center">
                    Erstellt am: <strong>{protocol.created_at}</strong>
                </div>
                <div className="right">Seite 1</div>
            </div>
        </div>
    );
}
