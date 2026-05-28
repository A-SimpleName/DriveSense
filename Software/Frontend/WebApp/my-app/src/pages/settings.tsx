// import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/authContext";
import { Button } from "../components/button";

export default function Settings() {
    // const navigate = useNavigate();
    const { account } = useAuth();

    return (
        <>
            <h1>Einstellungen</h1>
            <h2>Account</h2>
            
            <p>Angemeldeter Account: {account?.firstName} {account?.lastName}</p>
            <p>Email: {account?.email}</p>

            <Button label="Passwort ändern" type="button" /*onClick={() => navigate("/change-password")}*/ />
            <Button label="Account löschen" type="button" /*onClick={() => navigate("/delete-account")}*/ />
        </>
    );
}
