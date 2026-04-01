import { BrowserRouter, Routes, Route,Navigate } from "react-router-dom";
import DashboardPage from "./pages/dashboard";
import TripsPage from "./pages/trips";
import LoginPage from "./pages/login";
import Vehicles from "./pages/vehicles";
import Settings from "./pages/settings";
import RideDetailPage from "./pages/rideDetailPage";
import ImpressumPage from "./pages/impressum";
import DatenschutzPage from "./pages/datenschutz";
import "./styles/app.css";
import AuthLayout from "./components/Layout/AuthLayout";
import SignUpPage from "./pages/signUp";
import { isAuthenticated as checkAuth } from "./services/auth";
import { useEffect, useState } from "react";
import { logout } from "./services/auth";
import SelectProfile from "./pages/SelectProfile";

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    setIsAuthenticated(checkAuth());
  }, []);

  const handleLogout = () => {
    logout();
    setIsAuthenticated(false);
  }


  return (
    <BrowserRouter>  
          <Routes>
            <Route path="/login" element={isAuthenticated ? <Navigate to="/select-profile" /> : <LoginPage onLoginSuccess={() => setIsAuthenticated(true)} />} />
            <Route path="/registrieren" element={isAuthenticated ? <Navigate to="/" /> : <SignUpPage />} />
            <Route path="/" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><DashboardPage /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="/fahrten" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><TripsPage /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="/fahrzeuge" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><Vehicles /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="/einstellungen" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><Settings /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="/fahrten/:id" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><RideDetailPage /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="/impressum" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><ImpressumPage /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="/datenschutz" element={isAuthenticated ? <AuthLayout onLogout={handleLogout}><DatenschutzPage /></AuthLayout> : <Navigate to="/login" />} />
            <Route path="*" element={<div>404 Not Found</div>} />
            <Route path="/select-profile" element={<SelectProfile />} />
          </Routes>
        
    </BrowserRouter>
  );
}

export default App;
