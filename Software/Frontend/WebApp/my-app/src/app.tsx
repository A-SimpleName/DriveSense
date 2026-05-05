import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

import { checkAuth } from "./services/auth";
import { getProfilesByAccount } from "./services/profileService";
import { getCurrentAccount } from "./services/accountService";
import type { AccountResponse } from "./model/account";

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
  const [isAuth, setIsAuth] = useState<boolean>(false);
  const [profileSelected, setProfileSelected] = useState<boolean>(false);
  const [profiles, setProfiles] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [account, setAccount] = useState<AccountResponse | null>(null);
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

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <BrowserRouter>
      {isAuth && profileSelected && (
        <TopBar setAccount={setAccount} account={account} />
      )}

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

        {/* EINGELOGGT, ABER KEIN PROFIL AKTIV */}
        {isAuth && !profileSelected && (
          <Route
            path="*"
            element={
              <SelectProfilePage
                profiles={profiles}
                setProfiles={setProfiles}
                onSelect={() => {
                  setProfileSelected(true);
                }}
              />
            }
          />
        )}

        {/* VOLLSTÄNDIG EINGELOGGT MIT PROFIL */}
        {isAuth && profileSelected && (
          <>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/trips" element={<TripsPage />} />
            <Route path="/trips/:id" element={<TripDetailPage />} />
            <Route path="/protocols/:id" element={<ProtocolDetail />} />
            <Route path="/vehicles" element={<Vehicles />} />
            <Route path="/settings" element={<Settings onSwitchProfile={() => {
              setProfileSelected(false);
            }} />} />
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