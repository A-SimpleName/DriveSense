import { BrowserRouter, Routes, Route } from "react-router-dom";
import DashboardPage from "./pages/dashboard";
import TripsPage from "./pages/trips";
import LoginPage from "./pages/login";
import Topbar from "./components/Layout/topbar";
import Vehicles from "./pages/vehicles";
import Settings from "./pages/settings";
import Footer from "./components/Layout/footer";
import RideDetailPage from "./pages/rideDetailPage";

function App() {
  return (
    <BrowserRouter>
      <Topbar />

      <Routes>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/fahrten" element={<TripsPage />} />       
        <Route path="/fahrzeuge" element={<Vehicles />} />
        <Route path="/einstellungen" element={<Settings />} />
        <Route path="/fahrten/:id" element={<RideDetailPage />} />
        <Route path="*" element={<div>404 Not Found</div>} />
      </Routes>
      <Footer />
    </BrowserRouter>
  );
}

export default App;