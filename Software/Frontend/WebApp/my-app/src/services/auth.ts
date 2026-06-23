import api from "../api/httpService";
import { toAppError } from "../errorHandling/errorHandling";

async function handleRequest<T>(request: Promise<T>): Promise<T> {
    try {
        return await request;
    } catch (err: any) {
        throw toAppError(err);
    }
}

export async function signUp(
    firstName: string,
    lastName: string,
    email: string,
    password: string,
    birthdate: string
) {
    return handleRequest(api.post("/account/signUp", {
        firstName,
        lastName,
        email,
        password,
        birthdate: birthdate ? birthdate.split("T")[0] : null,
    }));
}

export async function login(email: string, password: string) {
    return handleRequest(api.post("/account/login", {
        email,
        password,
    }));
}

export async function logout() {
    return handleRequest(api.post("/account/logout", {}));
}

export async function logoutProfile() {
    return handleRequest(api.post("/profiles/logout", {}));
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
    return handleRequest(api.post(
        `/account/select-profile?profileId=${profileId}`,
        {}
    ));
}

export async function verifyEmail(email: string, code: string) {
    return handleRequest(api.post("/account/verify-email", { email, code }));
}

export async function resendVerification(email: string) {
    return handleRequest(api.post("/account/resend-verification", { email }));
}

export async function changePassword(oldPassword: string, newPassword: string) {
    return handleRequest(api.put("/account/password", { oldPassword, newPassword }));
}

export async function forgotPassword(email: string) {
    return handleRequest(api.post("/account/forgot-password", { email }));
}

export async function resetPassword(email: string, code: string, newPassword: string) {
    return handleRequest(api.post("/account/reset-password", {
        email,
        code,
        newPassword,
    }));
}