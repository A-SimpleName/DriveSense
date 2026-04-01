import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate, useNavigate} from "react-router-dom";

import { checkAuth } from "./services/auth";
import { getProfilesByAccount } from "./services/profileService";

import TopBar from "./components/Layout/topbar";
import LoginPage from "./pages/login";
import SignUpPage from "./pages/signUp";
import SelectProfilePage from "./pages/selectProfile";
import DashboardPage from "./pages/dashboard";
import TripsPage from "./pages/trips";
import Vehicles from "./pages/vehicles";
import Settings from "./pages/settings";

export default function App() {
  const [isAuth, setIsAuth] = useState<boolean>(false);
  const [profileSelected, setProfileSelected] = useState<boolean>(false);
  const [profiles, setProfiles] = useState<import("./model/profile").Profile[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [user, setUser] = useState(null);

  useEffect(() => {
    async function initAuth() {
      try {
        const auth = await checkAuth();
        setIsAuth(auth);

        if (auth) {
          const profiles = await getProfilesByAccount();
          setProfiles(profiles);
          setProfileSelected(profiles.length > 0);
        }
      } catch (e) {
        setIsAuth(false);
        setProfileSelected(false);
      } finally {
        setLoading(false);
      }
    }

    initAuth();
  }, []);

  if (loading) {
    return <div>Loading...</div>;
  }

  return (

    <BrowserRouter>

      {isAuth && profileSelected && (
        <TopBar setUser={setUser} />
      )}

      <Routes>
        {!isAuth && (
          <>
            <Route path="/login" element={<LoginPage onLoginSuccess={() => setIsAuth(true)} />} />
            <Route path="/signup" element={<SignUpPage />} />
            <Route path="*" element={<Navigate to="/login" />} />
          </>
        )}

        {isAuth && !profileSelected && (
          <>
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
          </>
        )}

        {isAuth && profileSelected && (
          <>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/trips" element={<TripsPage />} />
            <Route path="/vehicles" element={<Vehicles />} />
            <Route path="/settings" element={<Settings />} />
          </>
        )}
      </Routes>
    </BrowserRouter>
  );
}