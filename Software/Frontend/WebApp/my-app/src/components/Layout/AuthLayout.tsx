import Footer from "./footer";
import Topbar from "./topbar";

type AuthLayoutProps = {
  children: React.ReactNode;
  onLogout: () => void;
};

function AuthLayout({ children, onLogout }: AuthLayoutProps) {

    return ( 
        <div className="app-container">
            <Topbar onLogout={onLogout} />
            <main className="main-content">
                {children}
            </main>
            <Footer />
        </div> 
    );
}

export default AuthLayout;

