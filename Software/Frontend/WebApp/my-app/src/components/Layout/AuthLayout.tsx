import Footer from "./footer";
import Topbar from "./topbar";

type AuthLayoutProps = {
  children: React.ReactNode;
  setUser: React.Dispatch<React.SetStateAction<any>>;
};

export function AuthLayout({ children, setUser }: AuthLayoutProps) {

    return ( 
        <div className="app-container">
            <Topbar setUser={setUser} />
            <main className="main-content">
                {children}
            </main>
            <Footer />
        </div> 
    );
}

export default AuthLayout;

