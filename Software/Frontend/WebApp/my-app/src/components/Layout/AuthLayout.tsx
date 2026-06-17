import { Outlet } from "react-router-dom";
import Footer from "./footer";
import Topbar from "./topbar";
import MobileWarningBanner from "./MobileWarningBanner";
import "../../styles/mobileWarningBanner.css";


export function AuthLayout() {
    return (
        <div className="app-container">
            <MobileWarningBanner />
            <Topbar />
            <main className="main-content">
                <Outlet />
            </main>
            <Footer />
        </div>
    );
}

export default AuthLayout;