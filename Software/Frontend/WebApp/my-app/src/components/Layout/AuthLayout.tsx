import Footer from "./footer";
import Topbar from "./topbar";

type AuthLayoutProps = {
  children: React.ReactNode;
  setAccount: React.Dispatch<React.SetStateAction<any>>;
  account: any;
};

export function AuthLayout({ children, setAccount, account }: AuthLayoutProps) {

    return ( 
        <div className="app-container">
            <Topbar setAccount={setAccount} account={account} />
            <main className="main-content">
                {children}
            </main>
            <Footer />
        </div> 
    );
}

export default AuthLayout;

