import type { ProtocolDetail } from "../../model/protocol";
import type { TripSummary } from "../../model/trip";
import styles from "../../styles/protocol.module.css";

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
                    <td className={styles.left}>
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
                        <td className={styles.left}>{trip.startPoint}</td>
                        <td className={styles.left}>{trip.endPoint}</td>
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
                        <td className={styles.left}>{trip.startPoint}</td>
                        <td className={styles.left}>{trip.endPoint}</td>
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
        <div className={styles.pdfContainer}>
            {/* HEADER */}
            <div className={styles.header}>
                <div className={styles.left}>
                    <span className={styles.brand}>
                        DRIVESENSE
                    </span>

                    <div className={styles.protoName}>
                        {isGroup
                            ? protocol.usergroup?.name
                            : protocol.name}
                    </div>

                    <div className={styles.protoSub}>
                        {isGroup
                            ? "Gruppenprotokoll"
                            : "Einzelprotokoll"}{" "}
                        · {type.toUpperCase()}
                    </div>
                </div>

                {!isGroup && (
                    <div className={styles.right}>
                        <div className={styles.protoSub}>
                            {protocol.created_by_account.fname}{" "}
                            {protocol.created_by_account.lname}
                        </div>

                        <div className={styles.userInfo}>
                            geb.{" "}
                            {new Date(
                                protocol.created_by_account.birthdate
                            ).toLocaleDateString("de-AT")}
                        </div>
                    </div>
                )}
            </div>

            <div className={styles.accent}></div>

            {/* SUMMARY */}
            <div className={styles.summary}>
                <div className={styles.sumCell}>
                    <div className={styles.sumVal}>
                        {totalKm} km
                    </div>

                    <div className={styles.sumLbl}>
                        Gesamtstrecke
                    </div>
                </div>

                <div className={styles.sumCell}>
                    <div className={styles.sumVal}>
                        {trips.length}
                    </div>

                    <div className={styles.sumLbl}>
                        Fahrten
                    </div>
                </div>
            </div>

            <div className={styles.sectionTitle}>
                Fahrtenübersicht
            </div>

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
                    {trips.map((trip, i) =>
                        renderRow(trip, i)
                    )}
                </tbody>
            </table>

            {/* FOOTER */}
            <div className={styles.footer}>
                <div className={styles.left}>
                    drivesense.app
                </div>

                <div className={styles.center}>
                    Erstellt am:{" "}
                    <strong>
                        {new Date(
                            protocol.created_at
                        ).toLocaleString("de-AT")}
                    </strong>
                </div>

                <div className={styles.right}>
                    Seite 1
                </div>
            </div>
        </div>
    );
}