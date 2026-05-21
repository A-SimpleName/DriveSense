import { Outlet } from "react-router-dom";
import Footer from "./footer";
import Topbar from "./topbar";


export function AuthLayout() {
    return (
        <div className="app-container">
            <Topbar />
            <main className="main-content">
                <Outlet />
            </main>
            <Footer />
        </div>
    );
}

export default AuthLayout;