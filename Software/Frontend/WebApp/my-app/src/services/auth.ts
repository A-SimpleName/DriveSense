import { apiFetch } from "../api/api-token";

const BASE_URL = "http://localhost:8080/api";

export async function signUp(fname: string, lname: string, email: string, password: string, birthdate: string) {
  const res = await fetch(`${BASE_URL}/account/signUp`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ fname, lname, email, password, birthdate: birthdate.split("T")[0] })
  });

  if (!res.ok) throw new Error("Registrierung fehlgeschlagen");
  return await res.json();
}

export async function login(email: string, password: string) {
  const res = await fetch("http://localhost:8080/api/account/login", {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ email, password })
  });

  if (!res.ok) throw new Error("Login fehlgeschlagen");

  return res.json();
}

export async function logout() {
  await fetch("http://localhost:8080/api/account/logout", {
    method: "POST",
    credentials: "include"
  });
}

export async function logoutProfile() {
    await fetch("http://localhost:8080/api/profiles/logout", {
        method: "POST",
        credentials: "include"
    });
}

export async function checkAuth() {
  const res = await apiFetch("http://localhost:8080/api/account");
  return res.ok;
}

export async function selectProfile(profileId: number) {
  const res = await apiFetch(
    `http://localhost:8080/api/account/select-profile?profileId=${profileId}`, {
      method: "POST",
      credentials: "include"
    }
  );

  if (!res.ok) throw new Error("Profil Auswahl fehlgeschlagen");

  return res.json();
}