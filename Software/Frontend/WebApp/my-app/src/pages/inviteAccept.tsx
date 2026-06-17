import { useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { verifyInvite, acceptInvite } from "../services/groupService";
import type { Profile } from "../model/profile";
import { InviteCodeForm } from "../components/inviteCodeForm";

function InviteAcceptPage() {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();

    const [code, setCode] = useState(searchParams.get("code") ?? "");
    const [profiles, setProfiles] = useState<Profile[]>([]);
    const [selectedProfileId, setSelectedProfileId] = useState<number | null>(null);
    const [step, setStep] = useState<"code" | "profile" | "success">("code");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleAccept = async () => {
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

    return (
        <div style={{ maxWidth: "400px", margin: "40px auto", display: "flex", flexDirection: "column", gap: "16px" }}>

            {step === "code" && (
                <InviteCodeForm
                    title="Einladung annehmen"
                    placeholder="6-stelliger Code"
                    maxLength={6}
                    onVerify={async codeValue => {
                        const data = await verifyInvite(codeValue)
                        setCode(codeValue);
                        setProfiles(data)
                        setStep("profile")
                    }}
                    onSuccess={() => {}}
                    onClose={() => navigate("/groups")}
                />
            )}

            {step === "profile" && (
                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                    <p>Mit welchem Profil möchtest du beitreten?</p>
                    {profiles.map(profile => (
                        <div
                            key={profile.id}
                            onClick={() => setSelectedProfileId(profile.id ?? null)}
                            style={{
                                padding: "12px",
                                border: selectedProfileId === profile.id ? "2px solid blue" : "1px solid #ccc",
                                borderRadius: "6px",
                                cursor: "pointer",
                            }}
                        >
                            {profile.name}
                        </div>
                    ))}
                    {error && <p style={{ color: "red" }}>{error}</p>}
                    <button onClick={handleAccept} disabled={!selectedProfileId || loading}>
                        {loading && (
                            <span style={{
                                display: "inline-block", width: "12px", height: "12px",
                                border: "2px solid rgba(255,255,255,0.35)", borderTopColor: "currentColor",
                                borderRadius: "50%", animation: "spin 0.6s linear infinite",
                                verticalAlign: "middle", marginRight: "6px",
                            }} />
                        )}
                        {loading ? "Wird beigetreten..." : "Beitreten"}
                    </button>
                </div>
            )}

            {step === "success" && (
                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                    <p style={{ color: "green" }}>Du bist der Gruppe erfolgreich beigetreten!</p>
                    <button onClick={() => navigate("/groups")}>Zu meinen Gruppen</button>
                </div>
            )}
        </div>
    );
}

export default InviteAcceptPage;