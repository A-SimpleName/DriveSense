import Footer from "./footer";
import Topbar from "./topbar";

type AuthLayoutProps = {
    children: React.ReactNode;
};

export function AuthLayout({ children }: AuthLayoutProps) {
    return ( 
        <div className="app-container">
            <Topbar />
            <main className="main-content">
                {children}
            </main>
            <Footer />
        </div> 
    );
}

export default AuthLayout;