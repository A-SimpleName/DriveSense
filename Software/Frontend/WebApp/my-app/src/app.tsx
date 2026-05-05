import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

import { checkAuth } from "./services/auth";
import { getProfilesByAccount } from "./services/profileService";
import { getCurrentAccount } from "./services/accountService";

import { AuthProvider, useAuth } from "./context/authContext";

import TopBar from "./components/Layout/topbar";
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
    profileSelected,
    setProfileSelected
  } = useAuth();

  const [profiles, setProfiles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [reloadAuth, setReloadAuth] = useState(0);

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

          setProfileSelected(false);
        } else {
          setProfiles([]);
          setProfileSelected(false);
        }
      } catch (err) {
        console.error("initAuth ERROR:", err);
        setIsAuth(false);
        setProfileSelected(false);
        setProfiles([]);
      } finally {
        setLoading(false);
      }
    }

    initAuth();
  }, [reloadAuth]);

  if (loading) return <div>Loading...</div>;

  return (
    <BrowserRouter>

      {/* Topbar nur wenn komplett eingeloggt */}
      {isAuth && profileSelected && <TopBar />}

      <Routes>

        {/* NICHT EINGELOGGT */}
        {!isAuth && (
          <>
            <Route
              path="/login"
              element={
                <LoginPage
                  onLoginSuccess={() => {
                    setIsAuth(true);
                    setReloadAuth(prev => prev + 1);
                  }}
                />
              }
            />
            <Route path="/signup" element={<SignUpPage />} />
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

        {/* VOLLSTÄNDIG EINGELOGGT */}
        {isAuth && profileSelected && (
          <>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/trips" element={<TripsPage />} />
            <Route path="/trips/:id" element={<TripDetailPage />} />
            <Route path="/protocols/:id" element={<ProtocolDetail />} />
            <Route path="/vehicles" element={<Vehicles />} />
            <Route path="/settings" element={<Settings/>}/>
            <Route path="/protocols" element={<ProtocolPage />} />
            <Route path="/groups" element={<GroupPage />} />
            <Route path="/groups/:id" element={<GroupDetailPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/invite" element={<InviteAcceptPage />} />
          </>
        )}
        
      </Routes>
    </BrowserRouter>
  );
}