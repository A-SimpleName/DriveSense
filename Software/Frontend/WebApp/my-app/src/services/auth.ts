// services/auth-service.ts

import api from "../api/httpService";

export async function signUp(
  fName: string,
  lName: string,
  email: string,
  password: string,
  birthdate: string
) {
  return api.post("/account/signUp", {
    fName,
    lName,
    email,
    password,
    birthdate: birthdate.split("T")[0],
  });
}

export async function login(email: string, password: string) {
  return api.post("/account/login", {
    email,
    password,
  });
}

export async function logout() {
  return api.post("/account/logout", {});
}

export async function logoutProfile() {
  return api.post("/profiles/logout", {});
}

export async function checkAuth() {
  try {
    await api.get("/account");
    return true;
  } catch {
    return false;
  }
}

export async function selectProfile(profileId: number) {
  return api.post(
    `/account/select-profile?profileId=${profileId}`,
    {}
  );
}