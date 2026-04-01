import { isAuthenticated, hasProfile, logout } from "./services/auth";
import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LoginPage from "./pages/login";
import SignUpPage from "./pages/signUp";
import SelectProfilePage from "./pages/selectProfile";
import DashboardPage from "./pages/dashboard";
import TripsPage from "./pages/trips";
import AuthLayout from "./components/Layout/AuthLayout";
import Vehicles from "./pages/vehicles";
import Settings from "./pages/settings";

export default function App() {
  const [isAuth, setIsAuth] = useState(false);
  const [profileSelected, setProfileSelected] = useState(false);

  useEffect(() => {
    setIsAuth(isAuthenticated());
    setProfileSelected(hasProfile());
  }, []);

  const handleLogout = () => {
    logout();
    setIsAuth(false);
    setProfileSelected(false);
  };

  return (
    <BrowserRouter>
      <Routes>

        {/* LOGIN */}
        <Route
          path="/login"
          element={
            isAuth
              ? <Navigate to={profileSelected ? "/" : "/select-profile"} />
              : <LoginPage onLoginSuccess={() => setIsAuth(true)} />
          }
        />

        {/* REGISTER */}
        <Route
          path="/registrieren"
          element={
            isAuth
              ? <Navigate to="/" />
              : <SignUpPage />
          }
        />

        {/* PROFILE AUSWAHL */}
        <Route
          path="/select-profile"
          element={
            !isAuth
              ? <Navigate to="/login" />
              : <SelectProfilePage onSelect={() => setProfileSelected(true)} />
          }
        />

        {/* PROTECTED ROUTES */}
        <Route
          path="/"
          element={
            isAuth && profileSelected
              ? <AuthLayout onLogout={handleLogout}><DashboardPage /></AuthLayout>
              : <Navigate to="/login" />
          }
        />

        <Route
          path="/trips"
          element={
            isAuth && profileSelected
              ? <AuthLayout onLogout={handleLogout}><TripsPage /></AuthLayout>
              : <Navigate to="/login" />
          }
        />

        {
          <Route
            path="/vehicles"
            element={
              isAuth && profileSelected
                ? <AuthLayout onLogout={handleLogout}><Vehicles /></AuthLayout>
                : <Navigate to="/login" />
            }
          />
          }
          {
          <Route
            path="/settings"
            element={
              isAuth && profileSelected
                ? <AuthLayout onLogout={handleLogout}><Settings /></AuthLayout>
                : <Navigate to="/login" />
            }
           />
        }

        <Route path="*" element={<div>404 Not Found</div>} />
      </Routes>
    </BrowserRouter>
  );
}