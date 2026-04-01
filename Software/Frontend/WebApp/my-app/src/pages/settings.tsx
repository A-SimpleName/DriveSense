import { Button } from "../components/button";

function Settings() {
    return (
        <div>
            <h1>Settings</h1>
            <div><label>Passwort ändern</label>
            <Button
                label="Passwort ändern"
            ></Button>
            </div>
           
            <label>Profil wechseln</label>
            <Button
                label="Profil wechseln"
            ></Button>

        </div>
    );
}

export default Settings;