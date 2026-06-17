import "./styles/app.css";
import "./styles/utilities.css";
import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

import { checkAuth } from "./services/auth";
import { getCurrentProfile, getProfilesByAccount } from "./services/profileService";
import { getCurrentAccount } from "./services/accountService";

import { AuthProvider, useAuth } from "./context/authContext";
import AuthLayout from "./components/Layout/AuthLayout";
import LoginPage from "./pages/login";
import SignUpPage from "./pages/signUp";
import SelectProfilePage from "./pages/selectProfile";
import DashboardPage from "./pages/dashboard";
import TripsPage from "./pages/trips";
import TripDetailPage from "./pages/tripDetailPage";
import Vehicles from "./pages/vehicles";
import Settings from "./pages/settings";
import ProtocolPage from "./pages/protocol";
import ProtocolDetail from "./pages/protocolDetail";
import GroupPage from "./pages/group";
import GroupDetailPage from "./pages/groupDetail";
import ProfilePage from "./pages/profile";
import InviteAcceptPage from "./pages/inviteAccept";
import VerifyEmailPage from "./pages/verifyEmail";
import ForgotPasswordPage from "./pages/forgotPassword";
import ResetPasswordPage from "./pages/resetPassword";
import AdminPage from "./pages/admin";
import ConfirmEmailChangePage from "./pages/confirmEmailChangePage";

export default function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

function AppContent() {
  const {
    isAuth,
    setIsAuth,
    setAccount,
    setProfile,
    profileSelected,
    setProfileSelected
  } = useAuth();

  const [profiles, setProfiles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [reloadAuth, setReloadAuth] = useState(0);
  const [needsVerification, setNeedsVerification] = useState(false);

  useEffect(() => {
    async function initAuth() {
      try {
        const auth = await checkAuth();
        setIsAuth(auth);

        if (auth) {
          const accountData = await getCurrentAccount();
          setAccount(accountData);

          const profilesData = await getProfilesByAccount();
          setProfiles(profilesData);

          try {
            const profileData = await getCurrentProfile();
            setProfile(profileData);
            setProfileSelected(true);
          } catch {
            setProfile(null);
            setProfileSelected(false);
          }
        } else {
          setProfiles([]);
          setProfile(null);
          setProfileSelected(false);
        }
      } catch (err) {
        console.error("initAuth ERROR:", err);
        setIsAuth(false);
        setProfile(null);
        setProfileSelected(false);
        setProfiles([]);
      } finally {
        setLoading(false);
      }
    }

    initAuth();
  }, [reloadAuth]);

  useEffect(() => {
    if (!isAuth || profileSelected) {
      return;
    }

    async function refreshProfiles() {
      try {
        const profilesData = await getProfilesByAccount();
        setProfiles(profilesData);
      } catch (err) {
        console.error("refreshProfiles ERROR:", err);
      }
    }

    refreshProfiles();
  }, [isAuth, profileSelected]);

  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh" }}>
        <span className="spinner" />
      </div>
    );
  }

  return (
    <BrowserRouter>
      <Routes>

        {/* NICHT EINGELOGGT */}
        {!isAuth && !needsVerification && (
            <>
                <Route path="/login" element={
                    <LoginPage
                        onLoginSuccess={() => { setIsAuth(true); setReloadAuth(prev => prev + 1); }}
                        onNeedsVerification={() => setNeedsVerification(true)}
                    />
                } />
                <Route path="/signup" element={
                    <SignUpPage onNeedsVerification={() => setNeedsVerification(true)} />
                } />
                <Route path="/forgot-password" element={<ForgotPasswordPage />} />
                <Route path="/reset-password" element={<ResetPasswordPage />} />
                <Route path="*" element={<Navigate to="/login" />} />
            </>
        )}

        {/* EINGELOGGT, ABER KEIN PROFIL */}
        {isAuth && !profileSelected && (
          <Route
            path="*"
            element={
              <SelectProfilePage
                profiles={profiles}
                setProfiles={setProfiles}
                onSelect={() => setProfileSelected(true)}
              />
            }
          />
        )}

        {!isAuth && needsVerification && (
            <Route path="*" element={
                <VerifyEmailPage onVerified={() => {
                    setNeedsVerification(false);
                    setIsAuth(true);
                    setReloadAuth(prev => prev + 1);
                }} />
            } />
        )}

        {/* VOLLSTÄNDIG EINGELOGGT */}
        {isAuth && profileSelected && (
          <Route path="/" element={<AuthLayout />}>
            <Route index element={<DashboardPage />} />
            <Route path="trips" element={<TripsPage />} />
            <Route path="trips/:id" element={<TripDetailPage />} />
            <Route path="protocols/:id" element={<ProtocolDetail />} />
            <Route path="vehicles" element={<Vehicles />} />
            <Route path="settings" element={<Settings />} />
            <Route path="protocols" element={<ProtocolPage />} />
            <Route path="groups" element={<GroupPage />} />
            <Route path="groups/:id" element={<GroupDetailPage />} />
            <Route path="profile" element={<ProfilePage />} />
            <Route path="invite" element={<InviteAcceptPage />} />
            <Route path="admin" element={<AdminPage />} />
            <Route path="confirm-email-change" element={<ConfirmEmailChangePage />} />
          </Route>
        )}
      </Routes>
    </BrowserRouter>
  );
}
