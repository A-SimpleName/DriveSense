// App.tsx
import { BrowserRouter, Routes, Route } from "react-router-dom";
import DashboardPage from "./pages/dashboard";
import TripsPage from "./pages/trips";
import LoginPage from "./pages/login";
import Topbar from "./components/Layout/topbar";
import Vehicles from "./pages/vehicles";
import Settings from "./pages/settings";
import MapPage from "./pages/map";
import Footer from "./components/Layout/footer";

function App() {
  return (
    <BrowserRouter>
      <Topbar />

      <Routes>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/trips" element={<TripsPage />} />       
        <Route path="/vehicles" element={<Vehicles />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/map" element={<MapPage />} />
        <Route path="*" element={<div>404 Not Found</div>} />
      </Routes>
      <Footer />
    </BrowserRouter>
  );
}

export default App;