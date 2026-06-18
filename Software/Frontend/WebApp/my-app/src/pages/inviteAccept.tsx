import { useEffect, useRef, useState } from "react";
import { useLocation, useNavigate, useSearchParams } from "react-router-dom";
import { InviteCodeForm } from "../components/inviteCodeForm";
import { useAuth } from "../context/authContext";
import type { Profile } from "../model/profile";
import { acceptInvite, verifyInvite } from "../services/groupService";
import { acceptVehicleInvite } from "../services/vehicleService";

type InviteType = "group" | "vehicle";

function normalizeInviteType(value: string | null): InviteType {
    return value?.trim().toLowerCase() === "vehicle" ? "vehicle" : "group";
}

function InviteAcceptPage() {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();
    const location = useLocation();
    const { isAuth } = useAuth();

    const inviteType = normalizeInviteType(searchParams.get("type"));
    const initialCode = searchParams.get("code") ?? "";

    const [code, setCode] = useState(initialCode);
    const [profiles, setProfiles] = useState<Profile[]>([]);
    const [selectedProfileId, setSelectedProfileId] = useState<number | null>(null);
    const [step, setStep] = useState<"code" | "profile" | "success">("code");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const handledInitialCode = useRef(false);

    const roleLabel = (role?: string | null) => {
        switch (role?.trim().toUpperCase()) {
            case "FAHRSCHUELER":
                return "Fahrschueler";
            case "BERUFSFAHRER":
                return "Berufsfahrer";
            case "PRIVAT":
                return "Privat";
            default:
                return role?.trim() || "Unbekannt";
        }
    };

    const isJoinable = (profile: Profile) => profile.joinable !== false;

    useEffect(() => {
        if (!isAuth || handledInitialCode.current || !initialCode.trim()) {
            return;
        }

        handledInitialCode.current = true;
        void handleCode(initialCode);
    }, [isAuth, initialCode]);

    const handleLoginRedirect = () => {
        sessionStorage.setItem("pendingInviteUrl", `${location.pathname}${location.search}`);
        navigate("/login");
    };

    const handleCode = async (rawCode: string) => {
        const trimmedCode = rawCode.trim();
        if (!trimmedCode) return;

        setLoading(true);
        setError(null);

        try {
            if (inviteType === "vehicle") {
                await acceptVehicleInvite(trimmedCode);
                setCode(trimmedCode);
                setStep("success");
                return;
            }

            const data = await verifyInvite(trimmedCode);
            setCode(trimmedCode);
            setProfiles(data);
            setSelectedProfileId(null);
            setStep("profile");
        } catch (err: any) {
            setError(err?.message || "Einladung konnte nicht geprueft werden");
        } finally {
            setLoading(false);
        }
    };

    const handleAcceptGroupInvite = async () => {
        if (!selectedProfileId) return;
        setLoading(true);
        setError(null);
        try {
            await acceptInvite(code.trim(), selectedProfileId);
            setStep("success");
        } catch (err: any) {
            setError(err?.message || "Fehler beim Annehmen der Einladung");
        } finally {
            setLoading(false);
        }
    };

    if (!isAuth) {
        return (
            <div style={{ maxWidth: "420px", margin: "40px auto", display: "flex", flexDirection: "column", gap: "16px" }}>
                <h2>Einladung annehmen</h2>
                <p>Bitte melde dich an, um diese Einladung anzunehmen.</p>
                <button onClick={handleLoginRedirect}>Anmelden</button>
            </div>
        );
    }

    return (
        <div style={{ maxWidth: "420px", margin: "40px auto", display: "flex", flexDirection: "column", gap: "16px" }}>
            {step === "code" && (
                <>
                    {initialCode.trim() && loading ? (
                        <div style={{ display: "flex", flexDirection: "column", gap: "12px", alignItems: "center" }}>
                            <span className="spinner" />
                            <p>Einladung wird geprueft...</p>
                        </div>
                    ) : (
                        <InviteCodeForm
                            title={inviteType === "vehicle" ? "Fahrzeug-Einladung annehmen" : "Gruppeneinladung annehmen"}
                            placeholder={inviteType === "vehicle" ? "Einladungscode" : "6-stelliger Code"}
                            maxLength={inviteType === "group" ? 6 : undefined}
                            onVerify={handleCode}
                            onSuccess={() => {}}
                            onClose={() => navigate(inviteType === "vehicle" ? "/vehicles" : "/groups")}
                        />
                    )}
                    {error && <p style={{ color: "red" }}>{error}</p>}
                </>
            )}

            {step === "profile" && (
                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                    <p>Mit welchem Profil moechtest du beitreten?</p>
                    {profiles.map(profile => (
                        <div
                            key={profile.id}
                            onClick={() => {
                                if (!isJoinable(profile)) {
                                    setSelectedProfileId(null);
                                    setError(profile.joinMessage || "Mit diesem Profiltyp ist der Beitritt nicht moeglich.");
                                    return;
                                }
                                setError(null);
                                setSelectedProfileId(profile.id ?? null);
                            }}
                            style={{
                                padding: "12px",
                                border: selectedProfileId === profile.id ? "2px solid blue" : "1px solid #ccc",
                                borderRadius: "6px",
                                cursor: isJoinable(profile) ? "pointer" : "not-allowed",
                                opacity: isJoinable(profile) ? 1 : 0.6,
                            }}
                        >
                            <strong>{profile.name}</strong>
                            <div style={{ marginTop: "4px", fontSize: "0.9rem", color: isJoinable(profile) ? "#555" : "#b45309" }}>
                                {isJoinable(profile)
                                    ? roleLabel(profile.role)
                                    : profile.joinMessage || "Mit diesem Profiltyp ist der Beitritt nicht moeglich."}
                            </div>
                        </div>
                    ))}
                    {profiles.length === 0 && <p>Kein Profil dieses Accounts kann dieser Gruppe beitreten.</p>}
                    {error && <p style={{ color: "red" }}>{error}</p>}
                    <button onClick={handleAcceptGroupInvite} disabled={!selectedProfileId || loading || !profiles.some(isJoinable)}>
                        {loading ? "Wird beigetreten..." : "Beitreten"}
                    </button>
                </div>
            )}

            {step === "success" && (
                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                    <p style={{ color: "green" }}>
                        {inviteType === "vehicle"
                            ? "Du hast die Fahrzeugeinladung erfolgreich angenommen."
                            : "Du bist der Gruppe erfolgreich beigetreten."}
                    </p>
                    <button onClick={() => navigate(inviteType === "vehicle" ? "/vehicles" : "/groups")}>
                        {inviteType === "vehicle" ? "Zu meinen Fahrzeugen" : "Zu meinen Gruppen"}
                    </button>
                </div>
            )}
        </div>
    );
}

export default InviteAcceptPage;
