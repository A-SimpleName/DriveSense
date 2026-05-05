import Footer from "./footer";
import Topbar from "./topbar";

type AuthLayoutProps = {
    children: React.ReactNode;
    setAccount: React.Dispatch<React.SetStateAction<any>>;
    account: any;
    onProfileSelect: () => void;
    setIsAuth: React.Dispatch<React.SetStateAction<boolean>>;
};

export function AuthLayout({ children, setAccount, account, onProfileSelect, setIsAuth }: AuthLayoutProps) {

    return ( 
        <div className="app-container">
            <Topbar setAccount={setAccount} account={account} onProfileSelect={onProfileSelect} setIsAuth={setIsAuth} />
            <main className="main-content">
                {children}
            </main>
            <Footer />
        </div> 
    );
}

export default AuthLayout;